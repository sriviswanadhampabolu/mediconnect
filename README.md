# MediConnect — AI-Powered Hyperlocal Pharmacy & Health Assistant

MediConnect is a full-stack, safety-first health assistant and hyperlocal pharmacy discovery platform. It uses a **12-agent orchestration graph** to triage symptoms, detect life-threatening emergencies, recommend safe OTC medications, block dangerous drug interactions, and connect users directly with small, local neighborhood pharmacies.

---

## 🌟 Mission Constraint & Business-Model Guardrails

Unlike large aggregator platforms that extract high margins from local chemists:
1. **Low Capped Commission:** Order commission on neighborhood shops is strictly capped at **5–10%** (configured at 6.5%), enforced as a constant at the server level.
2. **Direct Chemist Chat:** Customers can live-chat directly with local shop owners, preserving neighborhood trust.
3. **Generic Savings Calculator:** Displays branded-vs-generic price comparisons at triage and checkout, maximizing affordability for patients while keeping local shops competitive.
4. **Server-Side Payment Cap:** Auto-pay is strictly capped at a user-configured limit (e.g., ₹1,500). Any charge above the limit halts execution and requires explicit two-step authorization.

---

## 🤖 12-Agent Orchestration Architecture

```
                                  [ User Request ]
                                         │
                                         ▼
                                 [ 1. Master Agent ]
                                         │
                                         ▼
                             [ 2. Safety Agent (Veto) ]
                                    /         \
                      (Emergency)  /           \ (Cleared)
                                  ▼             ▼
                     [ 10. Emergency Agent ]  [ 4. Medical History Agent ]
                                  │             (Decrypts Allergies & Meds)
                                  ▼                     │
                     [ 9. Hospital Trauma ]             ▼
                                  │           [ 3. Symptom Agent ]
                                  ▼             /                \
                     [ 12. Records Agent ] (Routine)           (Chronic > 2 wks)
                                                ▼                         ▼
                              [ 5. Medicine Agent ]             [ 9. Hospital Agent ]
                              (Hardcoded Denylist                (Clinic Slot Booking)
                               & Allergy Checks)
                                       │
                                       ▼
                              [ 6. Home Remedy Agent ]
                              (Mild Supportive Care)
                                       │
                                       ▼
                              [ 7. Pharmacy Agent ]
                              (Hyperlocal Local Shops &
                               Generic Savings Calc)
                                       │
                                       ▼
                              [ 8. Order Agent ]
                              (6.5% Capped Commission)
                                       │
                                       ▼
                              [ 11. Payment Agent ]
                              (Server Limit Enforcement)
                                       │
                                       ▼
                              [ 12. Records Agent ]
                              (AES-256 Encrypted Store)
```

### Specialist Agent Directory
1. **Master Agent:** Parses intent, routes between specialist nodes, and returns execution breadcrumbs.
2. **Safety Agent:** Always runs FIRST on every turn. Has **absolute veto power**. If critical symptoms (chest pain, stroke signs, breathing failure, anaphylaxis) are identified, interrupts the routine loop immediately. Fails toward caution.
3. **Symptom Agent:** Predicts likely conditions from voice transcripts or text. Flags chronic/long-term symptoms (>2 weeks) to withhold automated medicine and route to clinical consultation.
4. **Medical History Agent:** Runs *before* the Medicine Agent. Decrypts and passes past allergies, chronic conditions, and active prescriptions.
5. **Medicine Recommendation Agent:** Evaluates candidate medicines against hardcoded rules:
   - **Route Denylist:** Never recommends ear drops, eye drops, or nasal sprays for automated OTC self-treatment.
   - **Schedule Denylist:** Blocks prescription-only drugs (antibiotics, steroids, sedatives).
   - **Allergy Cross-Check:** Blocks drugs contraindicated by user allergies (e.g. blocks Aspirin/NSAIDs for patients with documented allergy, suggesting safe Paracetamol alternatives).
6. **Home Remedy Agent:** For mild/normal symptoms only; provides safe, non-invasive supportive care (e.g., saline gargle, hydration, steam).
7. **Pharmacy Agent:** Discovers verified neighborhood chemists within walking distance using Haversine distance calculations and inventory checks.
8. **Order Agent:** Calculates order financials with transparent generic savings and the capped 6.5% commission fee.
9. **Hospital Agent:** Finds nearby specialty clinics and books physical appointments for chronic symptoms or trauma escalation.
10. **Emergency Agent:** Bypasses routine triage to auto-dispatch an ambulance ticket and broadcast GPS coordinates to emergency contacts.
11. **Payment Agent:** Enforces server-side payment limits. Denies automated transactions that exceed the user's configured threshold.
12. **Records Agent:** Writes triage history, prescriptions, and diagnoses to the database using AES-256 encryption at rest, accompanied by an immutable audit log.

---

## 📂 Project Structure

```
localmedai/
├── backend/
│   ├── main.py                     # FastAPI application & lifespan seeder
│   ├── config.py                   # App config, commission rate, encryption key
│   ├── database.py                 # SQLAlchemy connection & session manager
│   ├── seed_data.py                # Populates local pharmacies, inventory, & sample user
│   ├── requirements.txt            # Python dependencies
│   ├── security/
│   │   └── crypto.py               # Field-level AES-256 / Fernet encryption
│   ├── models/
│   │   └── entities.py             # User, MedicalRecord, Pharmacy, Order, AuditLog
│   ├── schemas/
│   │   └── pydantic_models.py      # Pydantic request/response schemas
│   ├── agents/
│   │   ├── state.py                # Graph state schema
│   │   ├── master_graph.py         # Master orchestrator & conditional routing
│   │   ├── safety_agent.py         # Hardcoded safety veto & emergency detector
│   │   ├── history_agent.py        # Decrypts allergies & active prescriptions
│   │   ├── symptom_agent.py        # Condition predictor & chronic symptom detector
│   │   ├── medicine_agent.py       # Denylists (eye/ear/nose/antibiotics) & allergy cross-check
│   │   ├── home_remedy_agent.py    # Supportive mild care
│   │   ├── pharmacy_agent.py       # Hyperlocal search & generic savings
│   │   ├── order_agent.py          # 5-10% capped commission order engine
│   │   ├── emergency_agent.py      # Ambulance dispatch & SOS broadcast
│   │   ├── hospital_agent.py       # Clinic booking
│   │   ├── payment_agent.py        # Server-side payment cap enforcement
│   │   └── records_agent.py        # Encrypted persistence & audit trail
│   ├── api/
│   │   ├── routes_triage.py        # REST & WebSocket triage endpoints
│   │   ├── routes_pharmacy.py      # Nearby shops, generic savings, & orders
│   │   ├── routes_records.py       # Profile, encrypted records, & audit logs
│   │   └── routes_emergency.py     # Manual 1-tap SOS dispatch
│   ├── static/                     # Interactive Mobile Simulator & Web Console
│   │   ├── index.html
│   │   ├── styles.css
│   │   └── app.js
│   └── tests/
│       └── test_agents.py          # 7 unit tests verifying safety, allergies, & limits
│
└── android/                        # Native Android Jetpack Compose App
    ├── build.gradle.kts
    ├── settings.gradle.kts
    └── app/
        ├── build.gradle.kts
        └── src/main/
            ├── AndroidManifest.xml
            └── java/com/mediconnect/app/
                ├── MainActivity.kt
                ├── ui/
                │   ├── theme/      # Color.kt, Theme.kt
                │   ├── navigation/ # NavRoutes.kt, MediConnectNavGraph.kt
                │   └── screens/    # 9 Core Compose screens:
                │       ├── OnboardingScreen.kt
                │       ├── HomeScreen.kt
                │       ├── TriageChatScreen.kt
                │       ├── PharmacyResultsScreen.kt
                │       ├── OrderTrackingScreen.kt
                │       ├── MedicalHistoryScreen.kt
                │       ├── EmergencyScreen.kt
                │       ├── PaymentSettingsScreen.kt
                │       └── HospitalBookingScreen.kt
                ├── model/          # TriageModels.kt, PharmacyModels.kt, ProfileModels.kt
                ├── network/        # ApiService.kt, RetrofitClient.kt
                └── viewmodel/      # TriageViewModel, PharmacyViewModel, ProfileViewModel
```

---

## 🚀 Running the Project

### 1. Run Backend & Interactive Web Simulator
```bash
# In the workspace root:
.\venv\Scripts\python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000 --reload
```
- Open **`http://127.0.0.1:8000/`** in your browser to open the **Interactive Mobile Simulator & Live Agent Inspector**.
- Open **`http://127.0.0.1:8000/docs`** for interactive Swagger API documentation.

### 2. Run Automated Unit Tests
```bash
.\venv\Scripts\python -m pytest backend/tests -v
```
All 7 safety tests pass:
- `test_safety_agent_emergency_veto` (Emergency symptoms trigger immediate ambulance dispatch)
- `test_medical_history_allergy_crosscheck` (Allergy to Aspirin/NSAIDs blocks candidate drugs)
- `test_restricted_formulations_denylist` (Eye/ear/nose drops and antibiotics are strictly blocked)
- `test_long_term_symptom_routing` (Chronic conditions route to hospital without auto-meds)
- `test_commission_rate_guardrails` (Ensures commission rate is strictly 5–10%)
- `test_payment_agent_server_side_limit` (Server-side limit blocks auto-pay above threshold)
- `test_encryption_at_rest` (Sensitive medical fields encrypted with AES-256)

### 3. Open Native Android App in Android Studio
1. Open Android Studio.
2. Select **Open** and select the `android/` directory.
3. Gradle will sync dependencies automatically (Jetpack Compose, Material3, Retrofit).
4. Run on an Android Emulator or physical device. (The app connects to `http://10.0.2.2:8000/` in the emulator, pointing to your local FastAPI server).
#   m e d i c o n n e c t  
 