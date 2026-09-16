import json
from datetime import datetime, timezone, timedelta
from backend.database import SessionLocal, Base, engine
from backend.models.entities import User, MedicalRecord, MedicationHistory, Pharmacy, Order, CustomerStoreChat, PasswordResetCode
from backend.security.crypto import encrypt_list, encrypt_data

SAMPLE_USER_ID = "usr-sample-001"
DEMO_USER_IDS = ["usr-sample-001", "usr-101"]

# ==============================================================================
# MASTER CATALOG OF 68+ MEDICINES ACROSS 10 ESSENTIAL CLINICAL CATEGORIES
# ==============================================================================
COMPREHENSIVE_MEDICINE_CATALOG = [
    # 1. Pain Relief & Antipyretics (Fever)
    {"id": "med-p01", "category": "Pain & Fever", "generic_name": "Paracetamol 500mg Tablet", "branded_name": "Crocin 500", "generic_price": 18.0, "branded_price": 45.0, "stock": 120, "requires_prescription": False},
    {"id": "med-p02", "category": "Pain & Fever", "generic_name": "Paracetamol 650mg Tablet", "branded_name": "Dolo 650", "generic_price": 24.0, "branded_price": 58.0, "stock": 140, "requires_prescription": False},
    {"id": "med-p03", "category": "Pain & Fever", "generic_name": "Ibuprofen 400mg Tablet", "branded_name": "Brufen 400", "generic_price": 22.0, "branded_price": 52.0, "stock": 95, "requires_prescription": False},
    {"id": "med-p04", "category": "Pain & Fever", "generic_name": "Aceclofenac 100mg + Paracetamol 325mg", "branded_name": "Zerodol-P", "generic_price": 32.0, "branded_price": 85.0, "stock": 80, "requires_prescription": False},
    {"id": "med-p05", "category": "Pain & Fever", "generic_name": "Diclofenac Diethylamine Gel 30g", "branded_name": "Volini Fast Pain Relief", "generic_price": 45.0, "branded_price": 115.0, "stock": 55, "requires_prescription": False},
    {"id": "med-p06", "category": "Pain & Fever", "generic_name": "Tramadol 37.5mg + Paracetamol 325mg (Rx)", "branded_name": "Ultracet Tablet", "generic_price": 58.0, "branded_price": 160.0, "stock": 30, "requires_prescription": True},
    {"id": "med-p07", "category": "Pain & Fever", "generic_name": "Mefenamic Acid 250mg + Dicyclomine 10mg", "branded_name": "Meftal-Spas Tablet", "generic_price": 28.0, "branded_price": 62.0, "stock": 70, "requires_prescription": False},
    {"id": "med-p08", "category": "Pain & Fever", "generic_name": "Ibuprofen 400mg + Paracetamol 325mg", "branded_name": "Combiflam Tablet", "generic_price": 25.0, "branded_price": 55.0, "stock": 110, "requires_prescription": False},
    {"id": "med-p09", "category": "Pain & Fever", "generic_name": "Naproxen 500mg Tablet (Rx)", "branded_name": "Naprosyn 500", "generic_price": 38.0, "branded_price": 92.0, "stock": 45, "requires_prescription": True},

    # 2. Cold, Cough & Respiratory Allergies
    {"id": "med-c01", "category": "Cold & Allergy", "generic_name": "Cetirizine 10mg Tablet", "branded_name": "Zyrtec / Cetzine 10", "generic_price": 15.0, "branded_price": 42.0, "stock": 110, "requires_prescription": False},
    {"id": "med-c02", "category": "Cold & Allergy", "generic_name": "Levocetirizine 5mg Tablet", "branded_name": "Levocet 5", "generic_price": 20.0, "branded_price": 56.0, "stock": 85, "requires_prescription": False},
    {"id": "med-c03", "category": "Cold & Allergy", "generic_name": "Montelukast 10mg + Levocetirizine 5mg", "branded_name": "Montair-LC", "generic_price": 48.0, "branded_price": 175.0, "stock": 65, "requires_prescription": False},
    {"id": "med-c04", "category": "Cold & Allergy", "generic_name": "Chlorpheniramine Maleate 4mg", "branded_name": "Piriton 4mg", "generic_price": 12.0, "branded_price": 28.0, "stock": 90, "requires_prescription": False},
    {"id": "med-c05", "category": "Cold & Allergy", "generic_name": "Dextromethorphan HBr Cough Syrup 100ml", "branded_name": "Benadryl DR Syrup", "generic_price": 42.0, "branded_price": 110.0, "stock": 45, "requires_prescription": False},
    {"id": "med-c06", "category": "Cold & Allergy", "generic_name": "Ambroxol 30mg + Guaiphenesin 50mg Syrup", "branded_name": "Mucolite Syrup", "generic_price": 38.0, "branded_price": 95.0, "stock": 40, "requires_prescription": False},
    {"id": "med-c07", "category": "Cold & Allergy", "generic_name": "Fexofenadine 120mg Tablet", "branded_name": "Allegra 120", "generic_price": 55.0, "branded_price": 185.0, "stock": 60, "requires_prescription": False},
    {"id": "med-c08", "category": "Cold & Allergy", "generic_name": "Phenylephrine + CPM + Paracetamol", "branded_name": "Sinarest Tablet", "generic_price": 26.0, "branded_price": 68.0, "stock": 95, "requires_prescription": False},
    {"id": "med-c09", "category": "Cold & Allergy", "generic_name": "Xylometazoline 0.1% Nasal Drops 10ml", "branded_name": "Otrivin Adult Nasal Spray", "generic_price": 38.0, "branded_price": 98.0, "stock": 50, "requires_prescription": False},
    {"id": "med-c10", "category": "Cold & Allergy", "generic_name": "Salbutamol 100mcg Inhaler 200 MDI (Rx)", "branded_name": "Asthalin Inhaler", "generic_price": 85.0, "branded_price": 195.0, "stock": 35, "requires_prescription": True},
    {"id": "med-c11", "category": "Cold & Allergy", "generic_name": "Budesonide 0.5mg Respules 2ml (Rx)", "branded_name": "Budecort 0.5 Respules", "generic_price": 95.0, "branded_price": 240.0, "stock": 30, "requires_prescription": True},

    # 3. Gastrointestinal & Acid Reflux
    {"id": "med-g01", "category": "Gastrointestinal", "generic_name": "Omeprazole 20mg Capsule", "branded_name": "Omez 20", "generic_price": 22.0, "branded_price": 62.0, "stock": 105, "requires_prescription": False},
    {"id": "med-g02", "category": "Gastrointestinal", "generic_name": "Pantoprazole 40mg Tablet", "branded_name": "Pan 40", "generic_price": 28.0, "branded_price": 88.0, "stock": 130, "requires_prescription": False},
    {"id": "med-g03", "category": "Gastrointestinal", "generic_name": "Rabeprazole 20mg + Domperidone 30mg", "branded_name": "Razo-D Capsule", "generic_price": 45.0, "branded_price": 145.0, "stock": 70, "requires_prescription": False},
    {"id": "med-g04", "category": "Gastrointestinal", "generic_name": "Magnesium & Aluminium Hydroxide Gel 200ml", "branded_name": "Digene Mint Gel", "generic_price": 55.0, "branded_price": 135.0, "stock": 48, "requires_prescription": False},
    {"id": "med-g05", "category": "Gastrointestinal", "generic_name": "Domperidone 10mg Tablet", "branded_name": "Vomistop 10", "generic_price": 16.0, "branded_price": 40.0, "stock": 85, "requires_prescription": False},
    {"id": "med-g06", "category": "Gastrointestinal", "generic_name": "Ondansetron 4mg MD Tablet", "branded_name": "Emeset 4 MD", "generic_price": 20.0, "branded_price": 55.0, "stock": 60, "requires_prescription": False},
    {"id": "med-g07", "category": "Gastrointestinal", "generic_name": "Loperamide 2mg Capsule", "branded_name": "Imodium 2", "generic_price": 15.0, "branded_price": 38.0, "stock": 50, "requires_prescription": False},
    {"id": "med-g08", "category": "Gastrointestinal", "generic_name": "Oral Rehydration Salts (ORS) Sachet 21.8g", "branded_name": "Electral WHO Sachet", "generic_price": 14.0, "branded_price": 22.0, "stock": 200, "requires_prescription": False},
    {"id": "med-g09", "category": "Gastrointestinal", "generic_name": "Magaldrate + Simethicone Suspension 200ml", "branded_name": "Gelusil MPS Liquid", "generic_price": 48.0, "branded_price": 125.0, "stock": 45, "requires_prescription": False},
    {"id": "med-g10", "category": "Gastrointestinal", "generic_name": "Liquid Paraffin + Milk of Magnesia 170ml", "branded_name": "Cremaffin Syrup", "generic_price": 65.0, "branded_price": 160.0, "stock": 40, "requires_prescription": False},
    {"id": "med-g11", "category": "Gastrointestinal", "generic_name": "Bisacodyl 5mg Laxative Tablet", "branded_name": "Dulcolax 5mg", "generic_price": 12.0, "branded_price": 28.0, "stock": 90, "requires_prescription": False},
    {"id": "med-g12", "category": "Gastrointestinal", "generic_name": "Dicyclomine 20mg + Paracetamol 500mg", "branded_name": "Cyclopam Tablet", "generic_price": 24.0, "branded_price": 58.0, "stock": 65, "requires_prescription": False},

    # 4. Antibiotics & Anti-Infectives (Prescription Regulated)
    {"id": "med-a01", "category": "Antibiotics", "generic_name": "Amoxicillin 500mg Capsule (Rx)", "branded_name": "Mox 500", "generic_price": 45.0, "branded_price": 110.0, "stock": 60, "requires_prescription": True},
    {"id": "med-a02", "category": "Antibiotics", "generic_name": "Azithromycin 500mg Tablet (Rx)", "branded_name": "Azee 500 / Azithral", "generic_price": 65.0, "branded_price": 140.0, "stock": 55, "requires_prescription": True},
    {"id": "med-a03", "category": "Antibiotics", "generic_name": "Ciprofloxacin 500mg Tablet (Rx)", "branded_name": "Ciplox 500", "generic_price": 35.0, "branded_price": 82.0, "stock": 40, "requires_prescription": True},
    {"id": "med-a04", "category": "Antibiotics", "generic_name": "Cefixime 200mg Tablet (Rx)", "branded_name": "Taxim-O 200", "generic_price": 52.0, "branded_price": 125.0, "stock": 45, "requires_prescription": True},
    {"id": "med-a05", "category": "Antibiotics", "generic_name": "Doxycycline 100mg Capsule (Rx)", "branded_name": "Doxicip 100", "generic_price": 28.0, "branded_price": 72.0, "stock": 50, "requires_prescription": True},
    {"id": "med-a06", "category": "Antibiotics", "generic_name": "Amoxicillin 500mg + Clavulanic Acid 125mg (Rx)", "branded_name": "Augmentin 625 Duo", "generic_price": 92.0, "branded_price": 220.0, "stock": 40, "requires_prescription": True},
    {"id": "med-a07", "category": "Antibiotics", "generic_name": "Cefuroxime Axetil 500mg Tablet (Rx)", "branded_name": "Ceftum 500", "generic_price": 110.0, "branded_price": 280.0, "stock": 35, "requires_prescription": True},
    {"id": "med-a08", "category": "Antibiotics", "generic_name": "Metronidazole 400mg Tablet (Rx)", "branded_name": "Metrogyl 400", "generic_price": 18.0, "branded_price": 42.0, "stock": 75, "requires_prescription": True},
    {"id": "med-a09", "category": "Antibiotics", "generic_name": "Norfloxacin 400mg + Tinidazole 600mg (Rx)", "branded_name": "Norflox-TZ Tablet", "generic_price": 38.0, "branded_price": 95.0, "stock": 50, "requires_prescription": True},

    # 5. Chronic Care, Blood Pressure & Diabetes
    {"id": "med-m01", "category": "Chronic Care", "generic_name": "Metformin 500mg SR Tablet", "branded_name": "Glycomet 500 SR", "generic_price": 18.0, "branded_price": 42.0, "stock": 150, "requires_prescription": True},
    {"id": "med-m02", "category": "Chronic Care", "generic_name": "Glimepiride 1mg Tablet", "branded_name": "Amaryl 1", "generic_price": 22.0, "branded_price": 68.0, "stock": 80, "requires_prescription": True},
    {"id": "med-m03", "category": "Chronic Care", "generic_name": "Telmisartan 40mg Tablet", "branded_name": "Telma 40", "generic_price": 35.0, "branded_price": 118.0, "stock": 100, "requires_prescription": True},
    {"id": "med-m04", "category": "Chronic Care", "generic_name": "Amlodipine 5mg Tablet", "branded_name": "Amlong 5", "generic_price": 15.0, "branded_price": 38.0, "stock": 90, "requires_prescription": True},
    {"id": "med-m05", "category": "Chronic Care", "generic_name": "Atorvastatin 10mg Tablet", "branded_name": "Atorva 10", "generic_price": 32.0, "branded_price": 95.0, "stock": 85, "requires_prescription": True},
    {"id": "med-m06", "category": "Chronic Care", "generic_name": "Sitagliptin 50mg Tablet (Rx)", "branded_name": "Januvia 50", "generic_price": 85.0, "branded_price": 240.0, "stock": 50, "requires_prescription": True},
    {"id": "med-m07", "category": "Chronic Care", "generic_name": "Telmisartan 40mg + Amlodipine 5mg", "branded_name": "Telma-AM Tablet", "generic_price": 46.0, "branded_price": 135.0, "stock": 70, "requires_prescription": True},
    {"id": "med-m08", "category": "Chronic Care", "generic_name": "Rosuvastatin 10mg Tablet (Rx)", "branded_name": "Rosuvas 10", "generic_price": 38.0, "branded_price": 120.0, "stock": 65, "requires_prescription": True},
    {"id": "med-m09", "category": "Chronic Care", "generic_name": "Nebivolol 5mg Tablet (Rx)", "branded_name": "Nebicard 5", "generic_price": 42.0, "branded_price": 115.0, "stock": 45, "requires_prescription": True},
    {"id": "med-m10", "category": "Chronic Care", "generic_name": "Cilnidipine 10mg Tablet (Rx)", "branded_name": "Cilacar 10", "generic_price": 36.0, "branded_price": 105.0, "stock": 55, "requires_prescription": True},

    # 6. Cardiac & Emergency
    {"id": "med-e01", "category": "Cardiac & Emergency", "generic_name": "Isosorbide Dinitrate 5mg Sublingual (Rx)", "branded_name": "Sorbitrate 5mg", "generic_price": 18.0, "branded_price": 48.0, "stock": 40, "requires_prescription": True},
    {"id": "med-e02", "category": "Cardiac & Emergency", "generic_name": "Aspirin 75mg Gastro-resistant Tablet", "branded_name": "Ecosprin 75", "generic_price": 8.0, "branded_price": 18.0, "stock": 130, "requires_prescription": False},
    {"id": "med-e03", "category": "Cardiac & Emergency", "generic_name": "Clopidogrel 75mg Tablet (Rx)", "branded_name": "Clopilet 75", "generic_price": 42.0, "branded_price": 125.0, "stock": 60, "requires_prescription": True},

    # 7. Dermatology & First Aid Topicals
    {"id": "med-d01", "category": "First Aid & Skin", "generic_name": "Povidone Iodine 5% Ointment 15g", "branded_name": "Betadine Antiseptic Ointment", "generic_price": 35.0, "branded_price": 78.0, "stock": 65, "requires_prescription": False},
    {"id": "med-d02", "category": "First Aid & Skin", "generic_name": "Clotrimazole + Beclomethasone Cream 20g", "branded_name": "Candid-B Cream", "generic_price": 42.0, "branded_price": 98.0, "stock": 50, "requires_prescription": False},
    {"id": "med-d03", "category": "First Aid & Skin", "generic_name": "Silver Sulfadiazine Burn Ointment 20g", "branded_name": "Burnol Plus / Silvadene", "generic_price": 38.0, "branded_price": 85.0, "stock": 40, "requires_prescription": False},
    {"id": "med-d04", "category": "First Aid & Skin", "generic_name": "Hydrocortisone 1% Topical Cream 15g", "branded_name": "Cortizone-10", "generic_price": 40.0, "branded_price": 92.0, "stock": 35, "requires_prescription": False},
    {"id": "med-d05", "category": "First Aid & Skin", "generic_name": "Framycetin Skin Cream 30g", "branded_name": "Soframycin Skin Cream", "generic_price": 28.0, "branded_price": 65.0, "stock": 60, "requires_prescription": False},
    {"id": "med-d06", "category": "First Aid & Skin", "generic_name": "Neomycin + Polymyxin B Ointment 20g", "branded_name": "Neosporin Ointment", "generic_price": 48.0, "branded_price": 110.0, "stock": 45, "requires_prescription": False},
    {"id": "med-d07", "category": "First Aid & Skin", "generic_name": "Calamine + Diphenhydramine Lotion 120ml", "branded_name": "Caladryl Lotion", "generic_price": 60.0, "branded_price": 145.0, "stock": 35, "requires_prescription": False},
    {"id": "med-d08", "category": "First Aid & Skin", "generic_name": "Ayurvedic Pain Relief Cream 30g", "branded_name": "Moov Pain Relief Cream", "generic_price": 45.0, "branded_price": 115.0, "stock": 55, "requires_prescription": False},
    {"id": "med-d09", "category": "First Aid & Skin", "generic_name": "Diclofenac Topical Pain Spray 55g", "branded_name": "Omnigel Fast Spray", "generic_price": 75.0, "branded_price": 170.0, "stock": 40, "requires_prescription": False},

    # 8. Vitamins, Minerals & Immunity
    {"id": "med-v01", "category": "Vitamins & Wellness", "generic_name": "Vitamin C 500mg Chewable Tablet", "branded_name": "Limcee 500 Orange", "generic_price": 15.0, "branded_price": 32.0, "stock": 180, "requires_prescription": False},
    {"id": "med-v02", "category": "Vitamins & Wellness", "generic_name": "Zinc + Multivitamin Tablet", "branded_name": "Zincovit Tablet", "generic_price": 48.0, "branded_price": 115.0, "stock": 120, "requires_prescription": False},
    {"id": "med-v03", "category": "Vitamins & Wellness", "generic_name": "Cholecalciferol (Vitamin D3) 60k IU Granules", "branded_name": "Calcirol 60K Sachet", "generic_price": 28.0, "branded_price": 65.0, "stock": 90, "requires_prescription": False},
    {"id": "med-v04", "category": "Vitamins & Wellness", "generic_name": "Vitamin B-Complex with Zinc", "branded_name": "Becosules Z Capsules", "generic_price": 26.0, "branded_price": 54.0, "stock": 110, "requires_prescription": False},
    {"id": "med-v05", "category": "Vitamins & Wellness", "generic_name": "Calcium 500mg + Vitamin D3 250 IU", "branded_name": "Shelcal 500", "generic_price": 42.0, "branded_price": 98.0, "stock": 95, "requires_prescription": False},
    {"id": "med-v06", "category": "Vitamins & Wellness", "generic_name": "Methylcobalamin + B-Complex Tablet", "branded_name": "Neurobion Forte Tablet", "generic_price": 22.0, "branded_price": 48.0, "stock": 140, "requires_prescription": False},
    {"id": "med-v07", "category": "Vitamins & Wellness", "generic_name": "Daily Multivitamin & Mineral Tablet", "branded_name": "Supradyn Daily Tablet", "generic_price": 32.0, "branded_price": 68.0, "stock": 100, "requires_prescription": False},
    {"id": "med-v08", "category": "Vitamins & Wellness", "generic_name": "Folic Acid 5mg Tablet", "branded_name": "Folvite 5mg", "generic_price": 14.0, "branded_price": 30.0, "stock": 110, "requires_prescription": False},

    # 9. Eye & Ear Drops
    {"id": "med-y01", "category": "Eye & Ear Care", "generic_name": "Ciprofloxacin 0.3% Eye/Ear Drops 10ml", "branded_name": "Ciplox Eye/Ear Drops", "generic_price": 20.0, "branded_price": 48.0, "stock": 50, "requires_prescription": False},
    {"id": "med-y02", "category": "Eye & Ear Care", "generic_name": "Carboxymethylcellulose 0.5% Lubricant", "branded_name": "Refresh Tears Eye Drops 10ml", "generic_price": 65.0, "branded_price": 165.0, "stock": 45, "requires_prescription": False},
    {"id": "med-y03", "category": "Eye & Ear Care", "generic_name": "Chlorbutol + Paradichlorobenzene Drops", "branded_name": "Otorex Ear Drops 10ml", "generic_price": 40.0, "branded_price": 92.0, "stock": 35, "requires_prescription": False},
    {"id": "med-y04", "category": "Eye & Ear Care", "generic_name": "Tobramycin 0.3% Ophthalmic Solution (Rx)", "branded_name": "Toba Eye Drops 5ml", "generic_price": 55.0, "branded_price": 140.0, "stock": 30, "requires_prescription": True},

    # 10. Pediatric Essentials
    {"id": "med-k01", "category": "Pediatric Essentials", "generic_name": "Paracetamol Paediatric Suspension 60ml", "branded_name": "Crocin 120 Syrup", "generic_price": 28.0, "branded_price": 65.0, "stock": 60, "requires_prescription": False},
    {"id": "med-k02", "category": "Pediatric Essentials", "generic_name": "Simethicone + Dill Oil Drops 15ml", "branded_name": "Colicaid Paediatric Drops", "generic_price": 36.0, "branded_price": 85.0, "stock": 45, "requires_prescription": False},
    {"id": "med-k03", "category": "Pediatric Essentials", "generic_name": "Zinc Sulphate Paediatric Solution 50ml", "branded_name": "Zinconia Oral Solution", "generic_price": 32.0, "branded_price": 75.0, "stock": 50, "requires_prescription": False},
]

from backend.security.auth import hash_password

def init_db_and_seed():
    Base.metadata.create_all(bind=engine)
    
    # Auto-migrate SQLite schema
    try:
        with engine.connect() as conn:
            user_cols = [row[1] for row in conn.exec_driver_sql("PRAGMA table_info(users)").fetchall()]
            if "email" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE users ADD COLUMN email VARCHAR(120)")
            if "password_hash" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE users ADD COLUMN password_hash VARCHAR(255)")
            if "role" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE users ADD COLUMN role VARCHAR(30) DEFAULT 'customer'")
            if "store_id" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE users ADD COLUMN store_id VARCHAR(36)")

            pharm_cols = [row[1] for row in conn.exec_driver_sql("PRAGMA table_info(pharmacies)").fetchall()]
            if "owner_user_id" not in pharm_cols:
                conn.exec_driver_sql("ALTER TABLE pharmacies ADD COLUMN owner_user_id VARCHAR(36)")

            em_cols = [row[1] for row in conn.exec_driver_sql("PRAGMA table_info(emergency_events)").fetchall()]
            if "token_id" not in em_cols:
                conn.exec_driver_sql("ALTER TABLE emergency_events ADD COLUMN token_id VARCHAR(50)")
            if "appointment_type" not in em_cols:
                conn.exec_driver_sql("ALTER TABLE emergency_events ADD COLUMN appointment_type VARCHAR(60)")
            conn.commit()
    except Exception:
        pass

    db = SessionLocal()
    try:
        # Seed Customer Demo Users
        for uid in DEMO_USER_IDS:
            existing_user = db.query(User).filter(User.id == uid).first()
            if existing_user:
                if not existing_user.email:
                    existing_user.email = "rahul@health.in" if uid == "usr-sample-001" else "rahul2@health.in"
                if not existing_user.password_hash:
                    existing_user.password_hash = hash_password("Demo123!")
                existing_user.role = "customer"
                db.commit()
            else:
                user = User(
                    id=uid,
                    name="Rahul Sharma",
                    contact="+91 98765 43210" if uid == "usr-sample-001" else "+91 98765 43211",
                    email="rahul@health.in" if uid == "usr-sample-001" else "rahul2@health.in",
                    password_hash=hash_password("Demo123!"),
                    role="customer",
                    address="Flat 402, Green Park Avenue, Sector 15, Gurgaon",
                    latitude=28.4680,
                    longitude=77.0420,
                    emergency_contacts=json.dumps([
                        {"name": "Ananya Sharma (Spouse)", "phone": "+91 98111 22233", "relation": "Spouse"},
                        {"name": "Dr. V. K. Sharma (Father)", "phone": "+91 98222 33344", "relation": "Father"}
                    ]),
                    payment_limit=1500.0
                )
                db.add(user)
                
                # Sample medical record with Aspirin/NSAID allergy
                med_rec = MedicalRecord(
                    user_id=uid,
                    condition="Mild Seasonal Allergies & Acid Sensitivity",
                    diagnosis_date=datetime.now(timezone.utc),
                    prescribing_source="doctor",
                    encrypted_notes=encrypt_data("Patient has documented adverse cutaneous reaction to Aspirin/NSAIDs."),
                    encrypted_allergies=encrypt_list(["Aspirin", "NSAIDs", "Penicillin"]),
                    encrypted_chronic_conditions=encrypt_list(["Mild Gastritis", "Occasional Rhinitis"])
                )
                db.add(med_rec)
                
                # Sample active medications
                med_hist = MedicationHistory(
                    user_id=uid,
                    medicine_name="Pantoprazole 40mg",
                    generic_name="Pantoprazole",
                    dosage="1 tablet before breakfast",
                    prescribed_by="Dr. Mehra (Gastroenterologist)",
                    active=True
                )
                db.add(med_hist)

        # Seed Pharmacy Owner Demo User
        owner_user = db.query(User).filter(User.id == "usr-owner-001").first()
        if not owner_user:
            owner_user = User(
                id="usr-owner-001",
                name="Ramesh Gupta",
                contact="+91 98101 23456",
                email="owner@sanjeevani.in",
                password_hash=hash_password("Demo123!"),
                role="pharmacy_owner",
                store_id="pharm-001",
                address="Shop #4, Sector 15 Market, Gurgaon",
                latitude=28.4682,
                longitude=77.0425,
                payment_limit=10000.0
            )
            db.add(owner_user)
        else:
            owner_user.name = "Ramesh Gupta"
            owner_user.role = "pharmacy_owner"
            owner_user.store_id = "pharm-001"
            owner_user.email = "owner@sanjeevani.in"
            owner_user.password_hash = hash_password("Demo123!")
            db.commit()

        # Helper to create customized inventory variation for each store
        def create_store_inventory(discount_factor=1.0, stock_multiplier=1.0):
            inv = []
            for m in COMPREHENSIVE_MEDICINE_CATALOG:
                item = dict(m)
                item["generic_price"] = round(m["generic_price"] * discount_factor, 1)
                item["stock"] = max(5, int(m["stock"] * stock_multiplier))
                inv.append(item)
            return inv

        # Defined Local Pharmacy Clusters Across Major Delhi-NCR Zones
        STORES_SEED_DATA = [
            # Cluster 1: Sector 15 Gurgaon
            {
                "id": "pharm-001",
                "name": "Sanjeevani Local Chemist",
                "latitude": 28.4682,
                "longitude": 77.0425,
                "address": "Shop #4, Sector 15 Market, Near Mother Dairy, Gurgaon",
                "phone": "+91 98101 23456",
                "owner_user_id": "usr-owner-001",
                "response_time_avg": 8,
                "rating": 4.9,
                "inv": create_store_inventory(0.95, 1.2)
            },
            {
                "id": "pharm-002",
                "name": "Gupta Medical & Day-Night Health Store",
                "latitude": 28.4690,
                "longitude": 77.0440,
                "address": "Booth 12, Main Commercial Complex, Sector 15, Gurgaon",
                "phone": "+91 98102 34567",
                "owner_user_id": None,
                "response_time_avg": 12,
                "rating": 4.7,
                "inv": create_store_inventory(1.0, 0.9)
            },
            {
                "id": "pharm-003",
                "name": "Jan Aushadhi Generic Kendra #108",
                "latitude": 28.4710,
                "longitude": 77.0450,
                "address": "Plot 5, Community Centre, Sector 14, Gurgaon",
                "phone": "+91 98103 45678",
                "owner_user_id": None,
                "response_time_avg": 16,
                "rating": 4.8,
                "inv": create_store_inventory(0.90, 1.5)
            },

            # Cluster 2: DLF Phase 2 / Cyber Hub / Cyber City
            {
                "id": "pharm-004",
                "name": "CyberMed Express & Wellness",
                "latitude": 28.4952,
                "longitude": 77.0895,
                "address": "Ground Floor, Building 10, DLF Cyber Hub, DLF Phase 2, Gurgaon",
                "phone": "+91 98104 56789",
                "owner_user_id": None,
                "response_time_avg": 10,
                "rating": 4.9,
                "inv": create_store_inventory(0.98, 1.3)
            },
            {
                "id": "pharm-005",
                "name": "Guardian Pharmacy Cyber City",
                "latitude": 28.4940,
                "longitude": 77.0880,
                "address": "Shop 22, Central Arcade, DLF Phase 2, Gurgaon",
                "phone": "+91 98105 67890",
                "owner_user_id": None,
                "response_time_avg": 14,
                "rating": 4.8,
                "inv": create_store_inventory(1.02, 1.1)
            },
            {
                "id": "pharm-006",
                "name": "Fortis Health Shoppe DLF",
                "latitude": 28.4965,
                "longitude": 77.0910,
                "address": "DLF Gateway Tower, Sector 24/25, Gurgaon",
                "phone": "+91 98106 78901",
                "owner_user_id": None,
                "response_time_avg": 15,
                "rating": 4.7,
                "inv": create_store_inventory(1.05, 1.0)
            },

            # Cluster 3: Sector 29 Leisure Valley
            {
                "id": "pharm-007",
                "name": "Sector 29 Wellness Chemist",
                "latitude": 28.4675,
                "longitude": 77.0655,
                "address": "SCO 31, Sector 29 Commercial Market, Gurgaon",
                "phone": "+91 98107 89012",
                "owner_user_id": None,
                "response_time_avg": 10,
                "rating": 4.9,
                "inv": create_store_inventory(0.96, 1.0)
            },
            {
                "id": "pharm-008",
                "name": "Leisure Valley QuickMeds",
                "latitude": 28.4680,
                "longitude": 77.0640,
                "address": "Near IFFCO Chowk Metro, Sector 29, Gurgaon",
                "phone": "+91 98108 90123",
                "owner_user_id": None,
                "response_time_avg": 12,
                "rating": 4.8,
                "inv": create_store_inventory(0.98, 1.2)
            },

            # Cluster 4: Golf Course Road / Sector 54
            {
                "id": "pharm-009",
                "name": "Golf Course MedZone Chemist",
                "latitude": 28.4415,
                "longitude": 77.1085,
                "address": "Plaza 54, Golf Course Road, Sector 54, Gurgaon",
                "phone": "+91 98109 01234",
                "owner_user_id": None,
                "response_time_avg": 11,
                "rating": 4.9,
                "inv": create_store_inventory(0.97, 1.1)
            },
            {
                "id": "pharm-010",
                "name": "W-Pratiksha Specialty Chemist",
                "latitude": 28.4425,
                "longitude": 77.1070,
                "address": "Sector 56/54 Junction, Golf Course Extension, Gurgaon",
                "phone": "+91 98110 12345",
                "owner_user_id": None,
                "response_time_avg": 14,
                "rating": 4.7,
                "inv": create_store_inventory(1.0, 1.0)
            },

            # Cluster 5: Sohna Road / Sector 48
            {
                "id": "pharm-011",
                "name": "Sohna Road LifeLine Medicos",
                "latitude": 28.4195,
                "longitude": 77.0395,
                "address": "Omaxe City Centre, Sohna Road, Sector 48, Gurgaon",
                "phone": "+91 98111 23456",
                "owner_user_id": None,
                "response_time_avg": 12,
                "rating": 4.8,
                "inv": create_store_inventory(0.96, 1.0)
            },
            {
                "id": "pharm-012",
                "name": "GoodHealth Chemist Sec 48",
                "latitude": 28.4180,
                "longitude": 77.0380,
                "address": "JMD Megapolis Market, Sohna Road, Gurgaon",
                "phone": "+91 98112 34567",
                "owner_user_id": None,
                "response_time_avg": 15,
                "rating": 4.7,
                "inv": create_store_inventory(1.0, 0.9)
            },

            # Cluster 6: Connaught Place / Central Delhi
            {
                "id": "pharm-013",
                "name": "CP Central Chemist & Surgical",
                "latitude": 28.6318,
                "longitude": 77.2170,
                "address": "Block B, Inner Circle, Connaught Place, New Delhi",
                "phone": "+91 98113 45678",
                "owner_user_id": None,
                "response_time_avg": 9,
                "rating": 4.9,
                "inv": create_store_inventory(0.98, 1.4)
            },
            {
                "id": "pharm-014",
                "name": "Janpath Day-Night Medicos",
                "latitude": 28.6280,
                "longitude": 77.2190,
                "address": "Near Janpath Metro, Connaught Place, New Delhi",
                "phone": "+91 98114 56789",
                "owner_user_id": None,
                "response_time_avg": 13,
                "rating": 4.8,
                "inv": create_store_inventory(1.0, 1.2)
            }
        ]

        for s in STORES_SEED_DATA:
            existing = db.query(Pharmacy).filter(Pharmacy.id == s["id"]).first()
            if existing:
                existing.name = s["name"]
                existing.latitude = s["latitude"]
                existing.longitude = s["longitude"]
                existing.address = s["address"]
                existing.phone = s["phone"]
                existing.inventory = json.dumps(s["inv"])
                existing.owner_user_id = s.get("owner_user_id")
            else:
                pharm = Pharmacy(
                    id=s["id"],
                    name=s["name"],
                    latitude=s["latitude"],
                    longitude=s["longitude"],
                    address=s["address"],
                    phone=s["phone"],
                    inventory=json.dumps(s["inv"]),
                    owner_user_id=s.get("owner_user_id"),
                    response_time_avg=s["response_time_avg"],
                    verified=True,
                    rating=s["rating"]
                )
                db.add(pharm)

        # Seed sample completed and active orders for pharm-001 (Sanjeevani Local Chemist)
        # to populate Owner Dashboard daily sales, top ordered medicines, and incoming orders
        existing_orders = db.query(Order).filter(Order.pharmacy_id == "pharm-001").all()
        if len(existing_orders) < 3:
            now = datetime.now(timezone.utc)
            sample_orders = [
                Order(
                    id="ord-demo-101",
                    user_id="usr-sample-001",
                    pharmacy_id="pharm-001",
                    items=json.dumps([
                        {"medicine_name": "Paracetamol 650mg Tablet", "is_generic": True, "unit_price": 24.0, "quantity": 2},
                        {"medicine_name": "Pantoprazole 40mg Tablet", "is_generic": True, "unit_price": 28.0, "quantity": 1}
                    ]),
                    status="DELIVERED",
                    subtotal=76.0,
                    generic_savings=78.0,
                    total_amount=80.94,
                    commission_applied=4.94,
                    created_at=now - timedelta(hours=4)
                ),
                Order(
                    id="ord-demo-102",
                    user_id="usr-101",
                    pharmacy_id="pharm-001",
                    items=json.dumps([
                        {"medicine_name": "Paracetamol 650mg Tablet", "is_generic": True, "unit_price": 24.0, "quantity": 3},
                        {"medicine_name": "Azithromycin 500mg Tablet (Rx)", "is_generic": True, "unit_price": 65.0, "quantity": 1},
                        {"medicine_name": "Vitamin C 500mg Chewable Tablet", "is_generic": True, "unit_price": 15.0, "quantity": 2}
                    ]),
                    status="CONFIRMED",
                    subtotal=167.0,
                    generic_savings=145.0,
                    total_amount=177.86,
                    commission_applied=10.86,
                    created_at=now - timedelta(minutes=45)
                ),
                Order(
                    id="ord-demo-103",
                    user_id="usr-sample-001",
                    pharmacy_id="pharm-001",
                    items=json.dumps([
                        {"medicine_name": "Oral Rehydration Salts (ORS) Sachet 21.8g", "is_generic": True, "unit_price": 14.0, "quantity": 4},
                        {"medicine_name": "Pantoprazole 40mg Tablet", "is_generic": True, "unit_price": 28.0, "quantity": 2}
                    ]),
                    status="PLACED",
                    subtotal=112.0,
                    generic_savings=118.0,
                    total_amount=119.28,
                    commission_applied=7.28,
                    created_at=now - timedelta(minutes=15)
                ),
            ]
            for o in sample_orders:
                db.add(o)

        # Seed sample chat messages between customer and store owner
        existing_chats = db.query(CustomerStoreChat).filter(CustomerStoreChat.pharmacy_id == "pharm-001").all()
        if len(existing_chats) < 2:
            now = datetime.now(timezone.utc)
            db.add(CustomerStoreChat(
                pharmacy_id="pharm-001",
                user_id="usr-sample-001",
                sender_role="customer",
                sender_name="Rahul Sharma",
                message="Hello Ramesh ji, do you have Dolo 650 and Pan 40 in stock right now?",
                created_at=now - timedelta(minutes=30)
            ))
            db.add(CustomerStoreChat(
                pharmacy_id="pharm-001",
                user_id="usr-sample-001",
                sender_role="owner",
                sender_name="Ramesh Gupta (Owner)",
                message="Yes Rahul ji! We have fresh stock of both. We can deliver to Sector 15 within 10 minutes.",
                created_at=now - timedelta(minutes=25)
            ))

        db.commit()
    finally:
        db.close()

if __name__ == "__main__":
    init_db_and_seed()
    print("Database initialized and seeded successfully!")
