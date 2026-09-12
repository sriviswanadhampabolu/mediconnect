// MediConnect — Easy, Accessible Health Assistant & Pharmacy Client
const API_BASE = window.location.origin + "/api";

// Active User Session State
let currentUserId = "usr-sample-001";
let currentUser = null;

// DOM Elements
const symptomInput = document.getElementById("symptomInput");
const sendBtn = document.getElementById("sendBtn");
const voiceBtn = document.getElementById("voiceRecordBtn");
const micStatusText = document.getElementById("micStatusText");
const chatStream = document.getElementById("chatStream");
const doctorAdviceCard = document.getElementById("doctorAdviceCard");
const chemistShopsBox = document.getElementById("chemistShopsBox");
const chemistList = document.getElementById("chemistList");
const fullChemistList = document.getElementById("fullChemistList");
const friendlyProgress = document.getElementById("friendlyProgress");
const friendlyProgressText = document.getElementById("friendlyProgressText");

// Live Order Tracker
const liveOrderTracker = document.getElementById("liveOrderTracker");
const trackerMedName = document.getElementById("trackerMedName");
const trackerShopName = document.getElementById("trackerShopName");
const trackerAmount = document.getElementById("trackerAmount");
const closeTrackerBtn = document.getElementById("closeTrackerBtn");
const callRunnerBtn = document.getElementById("callRunnerBtn");

// Search Chemist Stores
const storeSearchInput = document.getElementById("storeSearchInput");
const storeSearchBtn = document.getElementById("storeSearchBtn");

// Quick Presets
const presetAllergy = document.getElementById("presetAllergy");
const presetCold = document.getElementById("presetCold");
const presetAcidity = document.getElementById("presetAcidity");
const presetEmergency = document.getElementById("presetEmergency");

// SOS Elements
const sosHeaderBtn = document.getElementById("sosHeaderBtn");
const sosModal = document.getElementById("sosModal");
const cancelSosBtn = document.getElementById("cancelSosBtn");
const confirmSosBtn = document.getElementById("confirmSosBtn");
const emergencyDirectBtn = document.getElementById("emergencyDirectBtn");
const emergencyDispatchedBox = document.getElementById("emergencyDispatchedBox");
const sosBookingId = document.getElementById("sosBookingId");

// Tabs
const tabNavHealth = document.getElementById("tabNavHealth");
const tabNavStores = document.getElementById("tabNavStores");
const tabNavOrders = document.getElementById("tabNavOrders");
const tabNavCard = document.getElementById("tabNavCard");
const tabNavEmergency = document.getElementById("tabNavEmergency");

const viewHealthCheck = document.getElementById("viewHealthCheck");
const viewStores = document.getElementById("viewStores");
const viewOrders = document.getElementById("viewOrders");
const viewHealthCard = document.getElementById("viewHealthCard");
const viewEmergency = document.getElementById("viewEmergency");
const inputFooterBar = document.getElementById("inputFooterBar");
const healthCardDetails = document.getElementById("healthCardDetails");

// Orders & Appointments Elements
const refreshOrdersBtn = document.getElementById("refreshOrdersBtn");
const ordersTabMedsBtn = document.getElementById("ordersTabMedsBtn");
const ordersTabApptsBtn = document.getElementById("ordersTabApptsBtn");
const panelOrderedMeds = document.getElementById("panelOrderedMeds");
const panelBookedAppts = document.getElementById("panelBookedAppts");
const userOrdersList = document.getElementById("userOrdersList");
const userAppointmentsList = document.getElementById("userAppointmentsList");
const ordersCountBadge = document.getElementById("ordersCountBadge");
const apptsCountBadge = document.getElementById("apptsCountBadge");

// Location Manager Elements
const openLocationModalBtn = document.getElementById("openLocationModalBtn");
const locationModal = document.getElementById("locationModal");
const closeLocationModalBtn = document.getElementById("closeLocationModalBtn");
const btnAutoDetectGps = document.getElementById("btnAutoDetectGps");
const gpsDetectStatus = document.getElementById("gpsDetectStatus");
const manualLocationForm = document.getElementById("manualLocationForm");
const manualAddressInput = document.getElementById("manualAddressInput");
const manualCityInput = document.getElementById("manualCityInput");
const manualPincodeInput = document.getElementById("manualPincodeInput");
const userLocationDisplay = document.getElementById("userLocationDisplay");

// Patient Profile Modal Elements
const openProfileBtn = document.getElementById("openProfileBtn");
const profileModal = document.getElementById("profileModal");
const closeProfileModalBtn = document.getElementById("closeProfileModalBtn");
const profileViewCard = document.getElementById("profileViewCard");
const profileEditForm = document.getElementById("profileEditForm");
const btnToggleEditProfile = document.getElementById("btnToggleEditProfile");
const btnCancelEditProfile = document.getElementById("btnCancelEditProfile");
const profileViewName = document.getElementById("profileViewName");
const profileViewPhone = document.getElementById("profileViewPhone");
const profileViewEmail = document.getElementById("profileViewEmail");
const profileViewAddress = document.getElementById("profileViewAddress");
const profileViewCoords = document.getElementById("profileViewCoords");
const profileViewAllergies = document.getElementById("profileViewAllergies");
const profileViewLimit = document.getElementById("profileViewLimit");
const profileViewContacts = document.getElementById("profileViewContacts");
const profileViewCreatedAt = document.getElementById("profileViewCreatedAt");

const editProfileName = document.getElementById("editProfileName");
const editProfileContact = document.getElementById("editProfileContact");
const editProfileEmail = document.getElementById("editProfileEmail");
const editProfileAddress = document.getElementById("editProfileAddress");
const editProfileLimit = document.getElementById("editProfileLimit");

// Patient Profile Banner Elements
const headerUserName = document.getElementById("headerUserName");
const headerUserSubtext = document.getElementById("headerUserSubtext");
const headerAllergyShield = document.getElementById("headerAllergyShield");
const headerSpendingCap = document.getElementById("headerSpendingCap");
const userAccountBtn = document.getElementById("userAccountBtn");
const headerAccountLabel = document.getElementById("headerAccountLabel");
const headerAvatarIcon = document.getElementById("headerAvatarIcon");
const headerLogoutBtn = document.getElementById("headerLogoutBtn");
const switchUserBtn = document.getElementById("switchUserBtn");
const logoutBtn = document.getElementById("logoutBtn");
const healthCardAuthActionBtn = document.getElementById("healthCardAuthActionBtn");

// Screen View Elements
const loginScreenView = document.getElementById("loginScreenView");
const dashboardAppView = document.getElementById("dashboardAppView");

// Auth Modal Elements
const authModal = document.getElementById("authModal");
const closeAuthModalBtn = document.getElementById("closeAuthModalBtn");
const tabSwitchLogin = document.getElementById("tabSwitchLogin");
const tabSwitchSignup = document.getElementById("tabSwitchSignup");
const loginFormPanel = document.getElementById("loginFormPanel");
const signupFormPanel = document.getElementById("signupFormPanel");
const loginIdentifier = document.getElementById("loginIdentifier");
const loginPassword = document.getElementById("loginPassword");
const toggleLoginPasswordBtn = document.getElementById("toggleLoginPasswordBtn");
const quickDemoBtn = document.getElementById("quickDemoBtn");
const linkToSignup = document.getElementById("linkToSignup");
const linkToLogin = document.getElementById("linkToLogin");
const signupName = document.getElementById("signupName");
const signupContact = document.getElementById("signupContact");
const signupEmail = document.getElementById("signupEmail");
const signupPassword = document.getElementById("signupPassword");
const toggleSignupPasswordBtn = document.getElementById("toggleSignupPasswordBtn");
const signupAddress = document.getElementById("signupAddress");
const signupAllergies = document.getElementById("signupAllergies");
const signupLimit = document.getElementById("signupLimit");

// Toast Notification
const toastNotification = document.getElementById("toastNotification");
const toastIcon = document.getElementById("toastIcon");
const toastMessage = document.getElementById("toastMessage");

let toastTimer = null;
function showToast(message, icon = "✅") {
  if (toastTimer) clearTimeout(toastTimer);
  toastIcon.textContent = icon;
  toastMessage.textContent = message;
  toastNotification.style.display = "flex";
  toastTimer = setTimeout(() => {
    toastNotification.style.display = "none";
  }, 4000);
}

// Close live order tracker
closeTrackerBtn.addEventListener("click", () => {
  liveOrderTracker.style.display = "none";
});

// Voice Assistant
let isRecording = false;
voiceBtn.addEventListener("click", () => {
  if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
    symptomInput.value = "I have a headache and body ache since morning";
    submitSymptom();
    return;
  }
  
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  const recognition = new SpeechRecognition();
  recognition.lang = 'en-US';
  
  if (!isRecording) {
    recognition.start();
    isRecording = true;
    voiceBtn.classList.add("listening");
    micStatusText.textContent = "Listening... Speak now";
  }
  
  recognition.onresult = (event) => {
    const text = event.results[0][0].transcript;
    symptomInput.value = text;
    isRecording = false;
    voiceBtn.classList.remove("listening");
    micStatusText.textContent = "Tap to Speak";
    submitSymptom();
  };
  
  recognition.onerror = () => {
    isRecording = false;
    voiceBtn.classList.remove("listening");
    micStatusText.textContent = "Tap to Speak";
  };
});

// Single-Tap Quick Problems
presetAllergy.addEventListener("click", () => {
  symptomInput.value = "I have a severe headache and body pain. What medicine can I take?";
  submitSymptom();
});

presetCold.addEventListener("click", () => {
  symptomInput.value = "I have a runny nose, sneezing, and a sore throat since yesterday.";
  submitSymptom();
});

presetAcidity.addEventListener("click", () => {
  symptomInput.value = "I have stomach burning, gas, and indigestion after eating.";
  submitSymptom();
});

presetEmergency.addEventListener("click", () => {
  symptomInput.value = "I am having sudden crushing chest pain and I cannot breathe!";
  submitSymptom();
});

// Send Message
sendBtn.addEventListener("click", submitSymptom);
symptomInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") submitSymptom();
});

// SOS Handlers
sosHeaderBtn.addEventListener("click", () => {
  sosModal.style.display = "flex";
});
cancelSosBtn.addEventListener("click", () => {
  sosModal.style.display = "none";
});
confirmSosBtn.addEventListener("click", () => {
  sosModal.style.display = "none";
  triggerAmbulanceSOS();
});
if (emergencyDirectBtn) {
  emergencyDirectBtn.addEventListener("click", triggerAmbulanceSOS);
}

async function triggerAmbulanceSOS() {
  showProgress("Contacting nearest emergency ambulance & booking ER bay...");
  try {
    const isOwner = currentUser?.role === "pharmacy_owner";
    const pickupLoc = isOwner ? "Apex Pharmacy, Shop #4, Sector 15 Market, Gurgaon" : (currentUser?.address || "Sector 15, Gurgaon");
    
    const res = await fetch(`${API_BASE}/emergency/trigger`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: currentUserId,
        reason: isOwner ? "Pharmacy Store Owner Emergency SOS (Shop #4 Sector 15)" : "User activated Emergency Ambulance SOS",
        location: pickupLoc
      })
    });
    const data = await res.json();
    hideProgress();
    
    // Show emergency banner in health view with auto-booked nearest hospital
    renderEmergencyBanner(data.summary, data);
    
    // Update emergency tab view
    if (emergencyDispatchedBox) {
      emergencyDispatchedBox.style.display = "block";
      const hosp = data.hospital_appointment_details || {};
      const hospName = hosp.hospital_name || "Metro Emergency Hospital";
      const token = hosp.token_id || data.emergency_event_id.slice(0, 8).toUpperCase();
      const dist = hosp.distance_km || "0.6";
      
      emergencyDispatchedBox.innerHTML = `
        <div class="sos-alert-badge">🚨 AMBULANCE DISPATCHED</div>
        <p class="sos-booking-code">Ambulance Booking: <strong>AMB-${data.emergency_event_id.slice(0, 6).toUpperCase()}</strong> (~7 mins arrival to ${isOwner ? 'Shop #4 Market' : 'Sector 15'})</p>
        <div class="sos-hospital-box">
          <div class="sos-hosp-pill">🏥 NEAREST HOSPITAL AUTO-BOOKED</div>
          <p class="sos-hosp-title">${hospName}</p>
          <p class="sos-hosp-meta">Distance: ${dist} km away • Token: <strong class="token-highlight">${token}</strong></p>
          <p class="sos-hosp-sub">Trauma ER admission pre-cleared. Emergency bed held immediately.</p>
        </div>
        <div style="margin-top: 14px; display: flex; gap: 10px; flex-wrap: wrap;">
          <a href="tel:108" class="neu-btn-primary" style="flex: 1; text-align: center; text-decoration: none; padding: 12px; font-weight: 800; background: #dc2626; color: #fff; border-radius: 12px; display: flex; align-items: center; justify-content: center; gap: 8px;">
            📞 Call Ambulance Direct (108)
          </a>
          <a href="tel:102" class="neu-pill-btn" style="flex: 1; text-align: center; text-decoration: none; padding: 12px; font-weight: 800; color: #991b1b; justify-content: center; border-radius: 12px; display: flex; align-items: center; gap: 8px;">
            📞 National SOS (102)
          </a>
        </div>
      `;
    }

    // Add confirmation chat bubble into chat stream for clear visibility
    const hosp = data.hospital_appointment_details || {};
    const hospName = hosp.hospital_name || "Metro Emergency Hospital";
    const token = hosp.token_id || data.emergency_event_id.slice(0, 8).toUpperCase();
    const dist = hosp.distance_km || "0.6";
    
    addChatBubble(`🚨 IMMEDIATE EMERGENCY ACTIVATED:
🚑 Ambulance (108) dispatched to: ${pickupLoc} (~7 mins arrival).
🏥 Nearest Hospital ER Auto-Booked: ${hospName} (${dist} km away).
🎫 Trauma ER Admission Token: ${token} (Pre-cleared, no waiting).
📞 Direct Ambulance Helpline: 108 / 102`, "assistant");
    
    showToast("🚨 Ambulance Dispatched & Nearest ER Auto-Booked!", "🚨");
  } catch (err) {
    hideProgress();
    showToast("Please call 108/102 immediately.", "⚠️");
  }
}

async function submitSymptom() {
  const query = symptomInput.value.trim();
  if (!query) return;

  symptomInput.value = "";
  
  // Add friendly user speech bubble
  addChatBubble(query, "user");
  
  doctorAdviceCard.style.display = "none";
  chemistShopsBox.style.display = "none";
  
  showProgress(currentUser?.role === "pharmacy_owner" ? "Analyzing symptoms for safe home remedies..." : "Checking with your health card for allergies...");
  
  try {
    const res = await fetch(`${API_BASE}/triage/message`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: currentUserId,
        message: query
      })
    });
    
    const data = await res.json();
    hideProgress();
    
    renderDoctorAdvice(data);
    
    // For owners: do NOT load nearby chemist stores for ordering
    if (currentUser?.role !== "pharmacy_owner" && !data.emergency_detected && !data.hospital_appointment_suggested) {
      loadNearbyChemists();
    }
  } catch (err) {
    hideProgress();
    addChatBubble("Sorry, we couldn't connect right now. Please check your internet connection.", "assistant");
  }
}

function showProgress(text) {
  friendlyProgress.style.display = "flex";
  friendlyProgressText.textContent = text;
}

function hideProgress() {
  friendlyProgress.style.display = "none";
}

function addChatBubble(text, sender) {
  const bubble = document.createElement("div");
  bubble.className = `chat-bubble ${sender}`;
  bubble.textContent = text;
  chatStream.appendChild(bubble);
  chatStream.scrollTop = chatStream.scrollHeight;
}

function renderEmergencyBanner(text, data = {}) {
  doctorAdviceCard.style.display = "flex";
  doctorAdviceCard.className = "doctor-advice-card emergency-alert";
  
  const hosp = data.hospital_appointment_details || {
    hospital_name: "Metro Trauma & Heart Hospital",
    distance_km: "0.6",
    token_id: "ER-URGENT-9"
  };

  doctorAdviceCard.innerHTML = `
    <div class="emergency-header-row">
      <span class="emergency-siren-icon">🚨</span>
      <div style="flex: 1;">
        <h3 class="emergency-card-title">CRITICAL EMERGENCY DETECTED</h3>
        <p class="emergency-alert-msg">${text}</p>
      </div>
    </div>
    
    <div class="emergency-hospital-auto-card">
      <div class="auto-book-pill">✓ PRE-BOOKED ER APPOINTMENT</div>
      <p class="hospital-name-text">${hosp.hospital_name}</p>
      <p class="hospital-meta-text">📍 ${hosp.distance_km} km away • Emergency Trauma Department</p>
      
      <div class="er-token-badge">
        <span class="token-label">Admission Token:</span>
        <strong class="token-code">${hosp.token_id}</strong>
      </div>
      <p class="token-subtext">Your token has been prioritized for immediate ER triage upon arrival.</p>
    </div>

    <div style="display: flex; gap: 10px; width: 100%; margin-top: 12px; flex-wrap: wrap;">
      <a href="tel:108" class="btn-call-hospital" style="flex: 1; text-align: center; text-decoration: none; display: inline-flex; align-items: center; justify-content: center; gap: 8px;">
        📞 Call Ambulance (108)
      </a>
      <a href="tel:102" class="btn-call-hospital" style="flex: 1; text-align: center; text-decoration: none; display: inline-flex; align-items: center; justify-content: center; gap: 8px; background: #b91c1c;">
        📞 Dial 102
      </a>
    </div>
    
    <button class="neu-pill-btn" onclick="switchMainTab('orders')" style="width: 100%; margin-top: 10px; padding: 12px; font-weight: 700; color: var(--text-title); justify-content: center; font-size: 13.5px;">
      📦 View ER Pass in Orders & Appointments ➔
    </button>
  `;
  doctorAdviceCard.scrollIntoView({ behavior: 'smooth' });
}

// Render dedicated Safe Home Remedies for Pharmacy Store Owners
function renderOwnerHomeRemedies(data) {
  if (chemistShopsBox) chemistShopsBox.style.display = "none";

  let remedies = (data.home_remedies && data.home_remedies.length > 0) ? data.home_remedies : [];
  const textLower = (data.ai_explanation || data.summary || "").toLowerCase();

  if (remedies.length === 0) {
    if (textLower.includes("headache") || textLower.includes("head") || textLower.includes("pain")) {
      remedies = [
        "Hydration: Drink 2 large glasses of lukewarm water or electrolyte infusion",
        "Cold/Warm Compress: Apply a damp cool cloth across your forehead and temples for 15 minutes",
        "Rest in Dim Light: Take a 20-minute break in a dark, quiet, well-ventilated space",
        "Gentle Acupressure: Gently massage temples, neck, and shoulder tension points"
      ];
    } else if (textLower.includes("cold") || textLower.includes("cough") || textLower.includes("throat")) {
      remedies = [
        "Steam Inhalation: Inhale warm steam with a drop of eucalyptus oil or ajwain for 8-10 minutes",
        "Warm Salt Water Gargle: Gargle with warm rock salt water 3 times a day to reduce throat swelling",
        "Herbal Kadha: Sip warm ginger, tulsi, turmeric, and black pepper water with raw honey",
        "Rest & Hydration: Keep well hydrated with warm soups and lukewarm fluids"
      ];
    } else if (textLower.includes("stomach") || textLower.includes("acid") || textLower.includes("gas") || textLower.includes("digestion")) {
      remedies = [
        "Cumin & Fennel Infusion: Boil 1 tsp jeera and saunf in water, strain and drink lukewarm",
        "Fresh Ginger: Chew a small piece of fresh ginger with a pinch of black salt",
        "Cold Skimmed Milk or Chaas: Sip half a glass of cold milk or roasted cumin buttermilk",
        "Light Diet: Eat simple khichdi or porridge; avoid fried, spicy food and tea/coffee"
      ];
    } else {
      remedies = [
        "Adequate Hydration: Drink plenty of water and clear broths throughout the day",
        "Restorative Rest: Give your body sufficient rest and avoid strenuous physical strain",
        "Light Wholesome Meals: Consume freshly prepared light food, fruit bowls, and warm teas",
        "Monitor Symptoms: Keep track of temperature and how you feel over the next few hours"
      ];
    }
  }

  // 1. Post Home Remedies directly into chat stream
  const remedyChatText = `🌿 Recommended Safe Home Remedies (घरेलू उपचार):\n\n` +
    remedies.map((r, i) => `${i + 1}. ${r}`).join("\n\n") +
    `\n\n💡 Clinical Guidance: ${data.ai_explanation || data.summary}\n\n` +
    `🚨 Emergency Notice: If you experience severe chest pain, breathlessness, or worsening distress, tap the red Emergency icon to call ambulance (108) and pre-book the nearest hospital ER.`;
  addChatBubble(remedyChatText, "assistant");

  // 2. Render dedicated Home Remedy card in doctorAdviceCard (NO medicine ordering)
  doctorAdviceCard.style.display = "flex";
  doctorAdviceCard.className = "doctor-advice-card home-remedy-card";

  doctorAdviceCard.innerHTML = `
    <div class="home-remedy-badge">🌿 SAFE HOME REMEDIES & NATURAL RECOVERY (घरेलू नुस्खे)</div>
    <div class="doctor-advice-text" style="margin-bottom: 16px; font-size: 14.5px; line-height: 1.6;">
      <strong>Clinical Assessment:</strong> ${data.ai_explanation || data.summary}
    </div>

    <div class="remedies-list" style="margin-bottom: 20px;">
      <h4 style="font-size: 14px; font-weight: 800; color: #064e3b; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;">
        <span>🍵</span> Natural Home Remedies & Supportive Care:
      </h4>
      ${remedies.map(r => `
        <div class="home-remedy-item">
          <span style="font-size: 20px;">🌱</span>
          <div>${r}</div>
        </div>
      `).join("")}
    </div>

    <!-- Emergency Call & Hospital ER Reservation Banner -->
    <div style="background: #fef2f2; border: 1.5px solid #fecaca; border-radius: 14px; padding: 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
      <div>
        <strong style="color: #991b1b; font-size: 14px; display: block;">🚨 Severe Pain, Breathlessness, or Emergency?</strong>
        <span style="font-size: 12.5px; color: #7f1d1d;">Instantly call ambulance (108) to your store & auto-book trauma ER admission at nearest hospital.</span>
      </div>
      <button class="owner-sos-btn" onclick="triggerAmbulanceSOS();" style="padding: 10px 18px; font-size: 13.5px;">
        <span>🚨 Call Ambulance (108) & Book ER</span>
      </button>
    </div>
  `;
  doctorAdviceCard.scrollIntoView({ behavior: 'smooth' });
}

function renderDoctorAdvice(data) {
  if (data.emergency_detected || data.severity === "emergency") {
    renderEmergencyBanner(data.ai_explanation || data.summary, data);
    return;
  }

  // If active user is Pharmacy Store Owner:
  // Provide safe home remedies directly in chat and card, suppress medicine ordering.
  if (currentUser && currentUser.role === "pharmacy_owner") {
    renderOwnerHomeRemedies(data);
    return;
  }

  doctorAdviceCard.style.display = "flex";
  doctorAdviceCard.className = "doctor-advice-card";

  const meds = data.medicines || data.recommended_medicines || [];
  const remedies = data.home_remedies || [];
  
  // Best deal: pharmacy offering highest discount for suitable medicine
  const bestDeal = data.best_discount_pharmacy || (meds.length > 0 ? {
    pharmacy_id: "pharm-001",
    pharmacy_name: "Sanjeevani Chemist",
    address: "Shop 4, Market Complex, Sector 15",
    distance_km: 0.3,
    medicine_name: meds[0].generic_name || "Paracetamol 500mg Tablet",
    generic_price: meds[0].average_generic_price || meds[0].approx_generic_price || 18.0,
    branded_price: meds[0].average_branded_price || meds[0].approx_branded_price || 45.0,
    savings: meds[0].savings_amount || 27.0,
    discount_percent: 60.0
  } : null);

  let html = `
    <div class="card-badge">🩺 SAFE DOCTOR ADVICE & OTC TRIAGE</div>
    <div class="doctor-advice-text">${data.ai_explanation || data.summary}</div>
  `;

  if (data.allergy_alerts && data.allergy_alerts.length > 0) {
    html += `
      <div class="blocked-warning-box">
        <h4>🛡️ Allergy Safety Shield Activated</h4>
        <p>${data.allergy_alerts.join("<br>")}</p>
      </div>
    `;
  }

  if (data.contraindication_warnings && data.contraindication_warnings.length > 0) {
    html += `
      <div class="blocked-warning-box">
        <h4>⚠️ Contraindication Safety Alert</h4>
        <p>${data.contraindication_warnings.join("<br>")}</p>
      </div>
    `;
  }

  // 1. SUGGEST HOME REMEDIES (Supportive Natural Care)
  if (remedies.length > 0) {
    html += `
      <div class="remedies-list">
        <h4>🌿 Safe Home Remedies (Supportive Care):</h4>
        <p style="font-size: 13px; color: var(--text-sub); margin-bottom: 12px; font-weight: 600;">
          Simple, effective natural measures you can take at home to relieve discomfort:
        </p>
        <ul>
          ${remedies.map(r => `<li>💧 ${r}</li>`).join("")}
        </ul>
      </div>
    `;
  }

  // 2. HIGHEST DISCOUNT NEAREST MEDICAL STORE & ORDER CONFIRMATION ASKING PROMPT
  if (bestDeal) {
    const discount = Math.round(bestDeal.discount_percent || 60);
    html += `
      <div class="auto-order-ask-card" id="autoOrderAskBox">
        <div class="order-ask-badge">🏷️ HIGHEST DISCOUNT MEDICAL STORE FOUND • ${discount}% OFF</div>
        
        <div class="order-ask-store-info">
          <div class="store-name-line">
            <span class="store-icon">🏪</span>
            <div>
              <strong class="store-title">${bestDeal.pharmacy_name}</strong>
              <span class="store-dist">📍 ${bestDeal.distance_km} km away • ${bestDeal.address}</span>
            </div>
          </div>
          
          <div class="store-med-row">
            <div>
              <div class="store-med-title">💊 ${bestDeal.medicine_name}</div>
              <div class="store-med-savings">
                <span class="price-val">₹${Number(bestDeal.generic_price).toFixed(0)}</span>
                <span class="mrp-val">MRP ₹${Number(bestDeal.branded_price).toFixed(0)}</span>
                <span class="discount-pill">Save ₹${Number(bestDeal.savings).toFixed(0)} (${discount}% OFF)</span>
              </div>
            </div>
          </div>
        </div>

        <div class="order-confirm-ask-section">
          <p class="order-confirm-question">
            💡 <strong>Your symptoms are mild.</strong> Would you like us to order <strong>${bestDeal.medicine_name}</strong> from <strong>${bestDeal.pharmacy_name}</strong> (lowest price with ${discount}% discount) for delivery to your address?
          </p>
          
          <div class="order-confirm-btn-group">
            <button class="btn-confirm-order" onclick="confirmMedicineOrder('${bestDeal.pharmacy_id}', '${bestDeal.pharmacy_name}', '${bestDeal.medicine_name}', ${bestDeal.generic_price})">
              ✓ Yes, Order Medicine (₹${Number(bestDeal.generic_price).toFixed(0)})
            </button>
            <button class="btn-decline-order" onclick="declineMedicineOrder()">
              🌿 No, Home Remedies Only
            </button>
          </div>
        </div>
      </div>
    `;
  }

  // 3. Recommended Generic Medicines List
  if (meds.length > 0) {
    html += `<div class="rec-section-heading">All Recommended Generic Medicines:</div>`;
    meds.forEach(m => {
      const genericPrice = m.average_generic_price || m.approx_generic_price || 18.0;
      const brandedPrice = m.average_branded_price || m.approx_branded_price || 45.0;
      const savings = Math.max(0, brandedPrice - genericPrice);
      const discount = Math.round((savings / brandedPrice) * 100);
      const dosage = m.dosage_and_usage || m.dosage_instructions || "Take as directed on label";
      
      html += `
        <div class="medicine-item">
          <div>
            <span class="med-name">${m.generic_name}</span>
            <div class="med-dosage">Dosage: ${dosage}</div>
            
            <div class="generic-savings-box">
              <span class="branded-price">Brand: ₹${brandedPrice.toFixed(0)}</span>
              <span class="generic-price">Generic: ₹${genericPrice.toFixed(0)}</span>
              <span class="savings-tag">Save ₹${savings.toFixed(0)} (${discount}% OFF)</span>
            </div>
          </div>
          
          <button class="btn-direct-order" onclick="quickOrderMedicine('${m.generic_name}', ${genericPrice})">
            ⚡ Quick Order (₹${genericPrice.toFixed(0)})
          </button>
        </div>
      `;
    });
  }

  // 4. Clinical specialist appointment if long-term
  if (data.hospital_appointment_suggested && !data.emergency_detected) {
    const hosp = data.hospital_appointment_details || { hospital_name: "City Specialty Clinic", token_id: "MED-CLINIC-4" };
    html += `
      <div class="emergency-hospital-auto-card clinic-card">
        <div class="auto-book-pill clinic-pill">🏥 IN-PERSON CLINIC VISIT RECOMMENDED</div>
        <p class="hospital-name-text">${hosp.hospital_name}</p>
        <div class="er-token-badge">
          <span class="token-label">Clinic Priority Slot:</span>
          <strong class="token-code blue">${hosp.token_id}</strong>
        </div>
        <p class="token-subtext">Since symptoms have persisted, a physical evaluation is recommended.</p>
      </div>
    `;
  }
  
  doctorAdviceCard.innerHTML = html;
  doctorAdviceCard.scrollIntoView({ behavior: 'smooth' });
}

window.confirmMedicineOrder = async function(pharmacyId, pharmacyName, medName, price) {
  const askBox = document.getElementById("autoOrderAskBox");
  if (askBox) {
    askBox.innerHTML = `
      <div class="order-confirmed-banner">
        <div style="font-size: 28px;">⏳</div>
        <div>
          <h4 style="color: #047857; font-size: 16px; font-weight: 800; margin-bottom: 2px;">Placing Order with ${pharmacyName}...</h4>
          <p style="color: #334155; font-size: 13.5px; font-weight: 600;">Securing ${medName} at ₹${price} with max discount.</p>
        </div>
      </div>
    `;
  }
  
  await orderFromChemist(pharmacyId, pharmacyName, medName, price);
  
  if (askBox) {
    askBox.innerHTML = `
      <div class="order-confirmed-banner" style="flex-direction: column; align-items: flex-start;">
        <div style="display: flex; align-items: center; gap: 14px;">
          <div style="font-size: 32px;">🎉</div>
          <div>
            <h4 style="color: #047857; font-size: 16px; font-weight: 800; margin-bottom: 2px;">Order Confirmed & Packing!</h4>
            <p style="color: #334155; font-size: 13.5px; font-weight: 600;"><strong>${pharmacyName}</strong> accepted your order for <strong>${medName}</strong> (₹${price}). Arriving in ~15 mins.</p>
          </div>
        </div>
        <button class="neu-pill-btn" onclick="switchMainTab('orders')" style="margin-top: 10px; font-size: 13px; font-weight: 700; padding: 8px 18px;">
          📦 View in Orders & Appointments ➔
        </button>
      </div>
    `;
  }
};

window.declineMedicineOrder = function() {
  const askBox = document.getElementById("autoOrderAskBox");
  if (askBox) {
    askBox.innerHTML = `
      <div class="order-declined-banner">
        <span style="font-size: 24px;">🌿</span>
        <p style="color: #334155; font-size: 14px; font-weight: 600;">
          No order placed. Please rest well, stay hydrated, and follow the natural home remedies suggested above!
        </p>
      </div>
    `;
  }
  showToast("Sticking with natural home remedies. Feel better soon!", "🌿");
};

// Quick Order directly from doctor recommendation card
window.quickOrderMedicine = async function(medName, price) {
  showProgress(`Placing order for ${medName} with nearest chemist...`);
  try {
    const res = await fetch(`${API_BASE}/pharmacy/orders/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: currentUserId,
        pharmacy_id: "pharm-001", // Sanjeevani Chemist (0.3km)
        items: [
          {
            medicine_name: medName,
            is_generic: true,
            unit_price: price,
            quantity: 1
          }
        ],
        payment_method: "UPI_AUTOPAY"
      })
    });
    
    const data = await res.json();
    hideProgress();
    
    // Display live order tracker banner
    displayLiveOrder(data.pharmacy_name, medName, data.total_amount);
    showToast(`Order Placed! ${medName} arriving in ~15 minutes.`, "🎉");
    
  } catch (err) {
    hideProgress();
    showToast("Could not place order. Please try again or call the shop.", "⚠️");
  }
};

function displayLiveOrder(shopName, medName, amount) {
  trackerMedName.textContent = medName;
  trackerShopName.textContent = `from ${shopName}`;
  trackerAmount.textContent = `₹${amount.toFixed(0)} Paid (Auto-Approved)`;
  liveOrderTracker.style.display = "flex";
  liveOrderTracker.scrollIntoView({ behavior: "smooth" });
}

callRunnerBtn.addEventListener("click", () => {
  showToast("Connecting call to Sanjeevani Chemist (+91 98101 23456)...", "📞");
});

async function loadNearbyChemists() {
  try {
    const res = await fetch(`${API_BASE}/pharmacy/nearby`);
    const shops = await res.json();
    chemistShopsBox.style.display = "flex";
    chemistList.innerHTML = "";
    
    shops.forEach(shop => {
      const card = createShopCard(shop);
      chemistList.appendChild(card);
    });
  } catch (err) {
    console.error("Failed to load chemists", err);
  }
}

function createShopCard(shop) {
  const card = document.createElement("div");
  card.className = "chemist-shop-card";
  
  const med = (shop.inventory && shop.inventory.length > 0) ? shop.inventory[0] : null;
  const price = med ? med.generic_price : 18;
  const medName = med ? med.generic_name : "Paracetamol 500mg";
  
  card.innerHTML = `
    <div class="shop-main-info">
      <div>
        <h4 class="shop-name-title">🏪 ${shop.name}</h4>
        <p class="shop-address-text">${shop.address}</p>
      </div>
      <span class="distance-badge">${shop.distance_km} km away</span>
    </div>
    <div class="shop-inventory-pill">
      Has <strong>${medName}</strong> in stock (Only ₹${price})
    </div>
    <div class="shop-action-buttons">
      <button class="btn-buy-medicine" onclick="orderFromChemist('${shop.id}', '${shop.name}', '${medName}', ${price})">
        Order for Delivery (₹${price})
      </button>
      <button class="btn-call-shop" onclick="callChemist('${shop.phone}', '${shop.name}')">
        📞 Call Shop
      </button>
    </div>
  `;
  return card;
}

window.orderFromChemist = async function(pharmacyId, pharmacyName, medName, price) {
  showProgress(`Placing order with ${pharmacyName}...`);
  try {
    const res = await fetch(`${API_BASE}/pharmacy/orders/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: currentUserId,
        pharmacy_id: pharmacyId,
        items: [
          {
            medicine_name: medName,
            is_generic: true,
            unit_price: price,
            quantity: 1
          }
        ],
        payment_method: "UPI_AUTOPAY"
      })
    });
    const data = await res.json();
    hideProgress();
    
    displayLiveOrder(pharmacyName, medName, data.total_amount);
    showToast(`Order Placed! ${pharmacyName} is packing your medicine.`, "🎉");
  } catch (err) {
    hideProgress();
    showToast("Could not place order. Please call the shop directly.", "⚠️");
  }
};

window.callChemist = function(phone, name) {
  showToast(`Calling ${name} at ${phone}...`, "📞");
};

// Search store input
if (storeSearchBtn) {
  storeSearchBtn.addEventListener("click", () => {
    const q = storeSearchInput.value.trim();
    loadFullChemistList(q);
  });
  storeSearchInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      const q = storeSearchInput.value.trim();
      loadFullChemistList(q);
    }
  });
}

// Top Navigation / Squircle Navigation Switching
if (tabNavHealth) tabNavHealth.addEventListener("click", () => switchMainTab("health"));
if (tabNavStores) tabNavStores.addEventListener("click", () => switchMainTab("stores"));
if (tabNavOrders) tabNavOrders.addEventListener("click", () => switchMainTab("orders"));
if (tabNavCard) tabNavCard.addEventListener("click", () => switchMainTab("card"));
if (tabNavEmergency) {
  tabNavEmergency.addEventListener("click", () => {
    if (currentUser?.role === "pharmacy_owner") {
      sosModal.style.display = "flex";
      const p = document.querySelector("#sosModal p");
      if (p) {
        p.innerHTML = "We will immediately dispatch the nearest ambulance (<strong>108</strong>) to your pharmacy store (<strong>Shop #4, Sector 15 Market</strong>) and auto-book trauma ER admission at the nearest hospital.";
      }
    } else {
      switchMainTab("emergency");
    }
  });
}

const ownerEmergencyBtn = document.getElementById("ownerEmergencyBtn");
if (ownerEmergencyBtn) {
  ownerEmergencyBtn.addEventListener("click", triggerAmbulanceSOS);
}

function switchMainTab(tab) {
  // Pharmacy owners cannot access medicine order store or patient health card
  if (currentUser?.role === "pharmacy_owner" && (tab === "stores" || tab === "card")) {
    tab = "health";
  }

  // Remove active class from all squircle buttons
  document.querySelectorAll(".neu-squircle-btn, .nav-tab").forEach(t => t.classList.remove("active"));
  
  // Hide all tab views and strip active class
  document.querySelectorAll(".tab-view").forEach(v => {
    v.classList.remove("active");
    v.style.display = "none";
  });
  
  if (tab === "health") {
    if (tabNavHealth) tabNavHealth.classList.add("active");
    if (viewHealthCheck) {
      viewHealthCheck.classList.add("active");
      viewHealthCheck.style.display = "flex";
      viewHealthCheck.style.flexDirection = "column";
    }
    if (inputFooterBar) inputFooterBar.style.display = "flex";
  } else if (tab === "stores") {
    if (tabNavStores) tabNavStores.classList.add("active");
    if (viewStores) {
      viewStores.classList.add("active");
      viewStores.style.display = "flex";
      viewStores.style.flexDirection = "column";
    }
    if (inputFooterBar) inputFooterBar.style.display = "none";
    loadFullChemistList();
  } else if (tab === "orders") {
    if (tabNavOrders) tabNavOrders.classList.add("active");
    if (viewOrders) {
      viewOrders.classList.add("active");
      viewOrders.style.display = "flex";
      viewOrders.style.flexDirection = "column";
    }
    if (inputFooterBar) inputFooterBar.style.display = "none";
    loadUserOrdersAndAppointments();
  } else if (tab === "card") {
    if (tabNavCard) tabNavCard.classList.add("active");
    if (viewHealthCard) {
      viewHealthCard.classList.add("active");
      viewHealthCard.style.display = "flex";
      viewHealthCard.style.flexDirection = "column";
    }
    if (inputFooterBar) inputFooterBar.style.display = "none";
    loadHealthCard();
  } else if (tab === "emergency") {
    if (tabNavEmergency) tabNavEmergency.classList.add("active");
    if (viewEmergency) {
      viewEmergency.classList.add("active");
      viewEmergency.style.display = "flex";
      viewEmergency.style.flexDirection = "column";
    }
    if (inputFooterBar) inputFooterBar.style.display = "none";
  }

  // Smooth scroll workspace into view
  const workspace = document.querySelector(".triage-workspace");
  if (workspace) {
    workspace.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}

async function loadFullChemistList(query = "") {
  fullChemistList.innerHTML = "<div style='color:#94a3b8; padding:10px;'>Finding trusted neighborhood medical stores...</div>";
  try {
    const url = query ? `${API_BASE}/pharmacy/nearby?query=${encodeURIComponent(query)}` : `${API_BASE}/pharmacy/nearby`;
    const res = await fetch(url);
    const shops = await res.json();
    fullChemistList.innerHTML = "";
    if (shops.length === 0) {
      fullChemistList.innerHTML = `<div style='color:#94a3b8; padding:10px;'>No stores found matching "${query}". Try searching for Paracetamol or Cetirizine.</div>`;
      return;
    }
    shops.forEach(shop => {
      fullChemistList.appendChild(createShopCard(shop));
    });
  } catch (e) {
    fullChemistList.innerHTML = "<div style='color:#ef4444;'>Failed to load shops.</div>";
  }
}

async function loadHealthCard() {
  healthCardDetails.innerHTML = "<div style='color:#94a3b8; padding:10px;'>Loading your safe health card...</div>";
  try {
    const res = await fetch(`${API_BASE}/records/user/${currentUserId}`);
    const data = await res.json();
    
    // Also sync local patient name if returned
    if (data.name) {
      headerUserName.textContent = data.name;
    }

    const allergiesList = (data.allergies && data.allergies.length > 0)
      ? data.allergies.map(a => `<div class="allergy-item">🛡️ Allergic to: ${a}</div>`).join("")
      : "<div style='font-size:12.5px; color:#94a3b8; padding:6px 0;'>No known allergies recorded. Add any adverse reactions below:</div>";

    const medsList = (data.active_medications && data.active_medications.length > 0)
      ? data.active_medications.map(m => `
          <div style="background:#0f172a; padding:8px 12px; border-radius:8px; font-size:13px; margin-bottom:4px;">
            <strong>${m.medicine_name}</strong> - ${m.dosage}
          </div>
        `).join("")
      : "<div style='font-size:12.5px; color:#94a3b8; padding:6px 0;'>No active prescribed medications.</div>";

    healthCardDetails.innerHTML = `
      <div class="health-info-box">
        <h4>👤 Patient Profile</h4>
        <p><strong>Name:</strong> ${data.name}</p>
        <p><strong>Contact:</strong> ${data.contact}</p>
        <p><strong>Delivery Address:</strong> ${data.address || "Sector 15, Gurgaon"}</p>
      </div>

      <div class="health-info-box">
        <h4 style="color:#f59e0b;">⚠️ My Medicine Allergies (Protected by AI Safety Guard)</h4>
        <p style="font-size:12px; color:#cbd5e1; margin-bottom:4px;">Medicines on this denylist are permanently blocked by the 12-agent graph from ever being recommended:</p>
        <div id="allergiesListContainer">
          ${allergiesList}
        </div>
        <div class="add-allergy-row">
          <input type="text" id="newAllergyInput" placeholder="Add allergy (e.g. Sulfa, Peanuts, Ibuprofen)..." />
          <button class="btn-add-allergy" onclick="submitNewAllergy()">+ Add & Encrypt</button>
        </div>
      </div>

      <div class="health-info-box">
        <h4 style="color:#38bdf8;">💊 Active Medications History</h4>
        ${medsList}
      </div>

      <div class="health-info-box">
        <h4 style="color:#10b981;">🔒 Safe Auto-Pay Limit Guardrail</h4>
        <p>Current server-enforced cap: <strong>₹${Number(data.payment_limit || 1500).toFixed(0)}</strong></p>
        <p style="font-size:12px; color:#94a3b8;">Any medicine order higher than this threshold is denied automatically and requires 2-step manual approval.</p>
        <div class="add-allergy-row" style="margin-top:6px;">
          <input type="number" id="newLimitInput" placeholder="New limit in ₹ (e.g. 2000)" value="${data.payment_limit || 1500}" />
          <button class="btn-add-allergy" onclick="submitNewPaymentLimit()">Update Limit</button>
        </div>
      </div>
    `;
  } catch (e) {
    healthCardDetails.innerHTML = "<div style='color:#ef4444;'>Could not load records. Please ensure server is running.</div>";
  }
}

window.submitNewAllergy = async function() {
  const input = document.getElementById("newAllergyInput");
  const allergy = input ? input.value.trim() : "";
  if (!allergy) return;
  
  try {
    const res = await fetch(`${API_BASE}/records/user/${currentUserId}/allergy?allergy=${encodeURIComponent(allergy)}`, {
      method: "POST"
    });
    if (res.ok) {
      showToast(`Allergy '${allergy}' added and encrypted.`, "🛡️");
      loadHealthCard();
    }
  } catch (e) {
    showToast("Failed to save allergy.", "⚠️");
  }
};

window.submitNewPaymentLimit = async function() {
  const input = document.getElementById("newLimitInput");
  const val = input ? parseFloat(input.value) : 0;
  if (!val || val <= 0) return;
  
  try {
    const res = await fetch(`${API_BASE}/records/user/${currentUserId}/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ payment_limit: val })
    });
    if (res.ok) {
      showToast(`Payment limit updated to ₹${val.toFixed(0)}.`, "🔒");
      headerSpendingCap.textContent = `🔒 Auto-Pay Cap: ₹${val.toFixed(0)}`;
      loadHealthCard();
    }
  } catch (e) {
    showToast("Failed to update limit.", "⚠️");
  }
};

// ==========================================================
// TACTILE 3D NEUMORPHIC GUARD TOGGLE
// ==========================================================
const systemToggleBtn = document.getElementById("systemToggleBtn");
if (systemToggleBtn) {
  systemToggleBtn.addEventListener("click", () => {
    systemToggleBtn.classList.toggle("active");
    const isOn = systemToggleBtn.classList.contains("active");
    showToast(
      isOn ? "AI Safety Guard & Allergy Shield: ACTIVE" : "Safety Shield in Advisory-Only Mode",
      isOn ? "🛡️" : "⚠️"
    );
  });
}

// ==========================================================
// MULTI-STEP AUTHENTICATION LOGIC (ROLE -> LOGIN -> FORGOT PASSWORD)
// ==========================================================

let selectedAuthRole = "customer"; // 'customer' or 'pharmacy_owner'
let currentPasswordResetEmail = "";

// Select role on Step 1
window.selectRole = function(role) {
  selectedAuthRole = role;
  const custCard = document.getElementById("roleCardCustomer");
  const ownerCard = document.getElementById("roleCardOwner");
  const continueText = document.getElementById("continueRoleBtnText");

  if (role === "customer") {
    if (custCard) {
      custCard.classList.add("selected");
      custCard.classList.remove("owner-selected");
      const r = custCard.querySelector(".role-card-radio");
      if (r) r.textContent = "✓";
    }
    if (ownerCard) {
      ownerCard.classList.remove("selected", "owner-selected");
      const r = ownerCard.querySelector(".role-card-radio");
      if (r) r.textContent = "";
    }
    if (continueText) continueText.textContent = "Continue as Patient";
  } else {
    if (ownerCard) {
      ownerCard.classList.add("owner-selected");
      ownerCard.classList.remove("selected");
      const r = ownerCard.querySelector(".role-card-radio");
      if (r) r.textContent = "✓";
    }
    if (custCard) {
      custCard.classList.remove("selected", "owner-selected");
      const r = custCard.querySelector(".role-card-radio");
      if (r) r.textContent = "";
    }
    if (continueText) continueText.textContent = "Continue as Pharmacy Owner";
  }
};

// Transition from Step 1 (Role Selection) to Step 2 (Credentials)
window.continueToCredentials = function() {
  const rolePanel = document.getElementById("roleSelectionPanel");
  const credPanel = document.getElementById("credentialsPanel");
  const forgotEmailPanel = document.getElementById("forgotEmailPanel");
  const forgotCodePanel = document.getElementById("forgotCodePanel");

  if (rolePanel) rolePanel.style.display = "none";
  if (credPanel) credPanel.style.display = "block";
  if (forgotEmailPanel) forgotEmailPanel.style.display = "none";
  if (forgotCodePanel) forgotCodePanel.style.display = "none";

  const chip = document.getElementById("currentRoleChip");
  const identLabel = document.getElementById("loginIdentifierLabel");
  const identInput = document.getElementById("loginIdentifier");
  const doLoginText = document.getElementById("doLoginBtnText");
  const storeGroup = document.getElementById("signupStoreNameGroup");
  const patientFields = document.getElementById("signupPatientFields");

  if (selectedAuthRole === "pharmacy_owner") {
    if (chip) {
      chip.textContent = "🏪 Pharmacy Owner";
      chip.classList.add("owner");
    }
    if (identLabel) identLabel.textContent = "Owner Email or Phone";
    if (identInput) {
      identInput.placeholder = "owner@sanjeevani.in or +91 98101 23456";
      identInput.value = "owner@sanjeevani.in";
    }
    if (doLoginText) doLoginText.textContent = "Sign In as Pharmacy Owner";
    if (storeGroup) storeGroup.style.display = "block";
    if (patientFields) patientFields.style.display = "none";
  } else {
    if (chip) {
      chip.textContent = "👤 Patient";
      chip.classList.remove("owner");
    }
    if (identLabel) identLabel.textContent = "Email or Mobile Number";
    if (identInput) {
      identInput.placeholder = "+91 98765 43210 or rahul@health.in";
      identInput.value = "rahul@health.in";
    }
    if (doLoginText) doLoginText.textContent = "Sign In as Patient";
    if (storeGroup) storeGroup.style.display = "none";
    if (patientFields) patientFields.style.display = "grid";
  }
  switchAuthTab("login");
};

// Back to Step 1 (Role Selection)
window.backToRoleSelect = function() {
  const credPanel = document.getElementById("credentialsPanel");
  const forgotEmailPanel = document.getElementById("forgotEmailPanel");
  const forgotCodePanel = document.getElementById("forgotCodePanel");
  const rolePanel = document.getElementById("roleSelectionPanel");

  if (credPanel) credPanel.style.display = "none";
  if (forgotEmailPanel) forgotEmailPanel.style.display = "none";
  if (forgotCodePanel) forgotCodePanel.style.display = "none";
  if (rolePanel) rolePanel.style.display = "block";
};

// Open Forgot Password View
window.openForgotPassword = function() {
  const identInput = document.getElementById("loginIdentifier");
  const emailInput = document.getElementById("forgotEmailInput");
  const identVal = identInput ? identInput.value.trim() : "";

  if (identVal.includes("@")) {
    if (emailInput) emailInput.value = identVal;
  } else {
    if (emailInput) emailInput.value = selectedAuthRole === "pharmacy_owner" ? "owner@sanjeevani.in" : "rahul@health.in";
  }

  const credPanel = document.getElementById("credentialsPanel");
  const forgotCodePanel = document.getElementById("forgotCodePanel");
  const forgotEmailPanel = document.getElementById("forgotEmailPanel");

  if (credPanel) credPanel.style.display = "none";
  if (forgotCodePanel) forgotCodePanel.style.display = "none";
  if (forgotEmailPanel) forgotEmailPanel.style.display = "block";
};

// Back from Forgot Password to Credentials
window.backToCredentials = function() {
  const forgotEmailPanel = document.getElementById("forgotEmailPanel");
  const credPanel = document.getElementById("credentialsPanel");

  if (forgotEmailPanel) forgotEmailPanel.style.display = "none";
  if (credPanel) credPanel.style.display = "block";
};

// Submit Send Reset Code (Calling /api/auth/forgot-password)
window.submitSendResetCode = async function() {
  const emailInput = document.getElementById("forgotEmailInput");
  const email = emailInput ? emailInput.value.trim().toLowerCase() : "";
  if (!email || !email.includes("@")) {
    showToast("Please enter a valid registered email address.", "⚠️");
    return;
  }

  showProgress("Sending 6-digit verification code to " + email + "...");
  try {
    const res = await fetch(`${API_BASE}/auth/forgot-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: email })
    });
    const data = await res.json();
    hideProgress();

    if (!res.ok || !data.success) {
      showToast(data.detail || "No account found with this email address.", "❌");
      return;
    }

    currentPasswordResetEmail = data.email || email;
    const sentLabel = document.getElementById("sentCodeEmailLabel");
    if (sentLabel) sentLabel.textContent = currentPasswordResetEmail;

    // Show dev code preview banner for local testing
    const banner = document.getElementById("devCodeBanner");
    const valSpan = document.getElementById("devCodeValue");
    if (data.dev_code) {
      if (valSpan) valSpan.textContent = data.dev_code;
      if (banner) banner.style.display = "flex";
    } else {
      if (banner) banner.style.display = "none";
    }

    const codeInput = document.getElementById("resetCodeInput");
    const newPassInput = document.getElementById("resetNewPassword");
    const confirmPassInput = document.getElementById("resetConfirmPassword");
    if (codeInput) codeInput.value = "";
    if (newPassInput) newPassInput.value = "";
    if (confirmPassInput) confirmPassInput.value = "";

    const forgotEmailPanel = document.getElementById("forgotEmailPanel");
    const forgotCodePanel = document.getElementById("forgotCodePanel");
    if (forgotEmailPanel) forgotEmailPanel.style.display = "none";
    if (forgotCodePanel) forgotCodePanel.style.display = "block";

    showToast(`Verification code sent to ${currentPasswordResetEmail}! Check your inbox.`, "📨");
  } catch (err) {
    hideProgress();
    showToast("Could not send code. Please check your network.", "⚠️");
  }
};

// Auto-fill Code for Quick Local Testing
window.autofillResetCode = function() {
  const valSpan = document.getElementById("devCodeValue");
  const code = valSpan ? valSpan.textContent.trim() : "";
  const codeInput = document.getElementById("resetCodeInput");
  if (codeInput && code) {
    codeInput.value = code;
    showToast("Code auto-filled: " + code, "🔑");
  }
};

// Back from Code to Email view
window.backToForgotEmail = function() {
  const forgotCodePanel = document.getElementById("forgotCodePanel");
  const forgotEmailPanel = document.getElementById("forgotEmailPanel");
  if (forgotCodePanel) forgotCodePanel.style.display = "none";
  if (forgotEmailPanel) forgotEmailPanel.style.display = "block";
};

// Submit Confirm Password Reset (Calling /api/auth/reset-password)
window.submitConfirmPasswordReset = async function() {
  const codeInput = document.getElementById("resetCodeInput");
  const newPassInput = document.getElementById("resetNewPassword");
  const confirmPassInput = document.getElementById("resetConfirmPassword");

  const code = codeInput ? codeInput.value.trim() : "";
  const newPass = newPassInput ? newPassInput.value.trim() : "";
  const confirmPass = confirmPassInput ? confirmPassInput.value.trim() : "";

  if (!code || code.length !== 6) {
    showToast("Please enter the valid 6-digit verification code.", "⚠️");
    return;
  }
  if (newPass.length < 4) {
    showToast("Password must be at least 4 characters.", "⚠️");
    return;
  }
  if (newPass !== confirmPass) {
    showToast("Passwords do not match. Please re-enter.", "⚠️");
    return;
  }

  showProgress("Verifying code & resetting password...");
  try {
    const res = await fetch(`${API_BASE}/auth/reset-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: currentPasswordResetEmail,
        code: code,
        new_password: newPass
      })
    });
    const data = await res.json();
    hideProgress();

    if (!res.ok || !data.success) {
      showToast(data.detail || "Invalid or expired verification code.", "❌");
      return;
    }

    showToast("Password reset successfully! Please sign in with your new password.", "🎉");

    // Pre-fill login credentials and switch to Login
    const identInput = document.getElementById("loginIdentifier");
    const passInput = document.getElementById("loginPassword");
    if (identInput) identInput.value = currentPasswordResetEmail;
    if (passInput) passInput.value = "";

    const forgotCodePanel = document.getElementById("forgotCodePanel");
    const credPanel = document.getElementById("credentialsPanel");
    if (forgotCodePanel) forgotCodePanel.style.display = "none";
    if (credPanel) credPanel.style.display = "block";
  } catch (err) {
    hideProgress();
    showToast("Password reset failed. Please try again.", "⚠️");
  }
};

function showLoginScreen(step = "role") {
  const loginScreen = document.getElementById("loginScreenView");
  const dashboard = document.getElementById("dashboardAppView");
  const authCard = document.getElementById("authModal");
  if (loginScreen) {
    loginScreen.style.display = "flex";
  }
  if (dashboard) {
    dashboard.style.display = "none";
  }
  if (authCard) {
    authCard.style.display = "block";
  }

  const rolePanel = document.getElementById("roleSelectionPanel");
  const credPanel = document.getElementById("credentialsPanel");
  const forgotEmailPanel = document.getElementById("forgotEmailPanel");
  const forgotCodePanel = document.getElementById("forgotCodePanel");

  if (step === "role") {
    if (rolePanel) rolePanel.style.display = "block";
    if (credPanel) credPanel.style.display = "none";
    if (forgotEmailPanel) forgotEmailPanel.style.display = "none";
    if (forgotCodePanel) forgotCodePanel.style.display = "none";
  } else {
    continueToCredentials();
  }

  const closeBtn = document.getElementById("closeAuthModalBtn");
  if (closeBtn) {
    closeBtn.style.display = currentUser ? "flex" : "none";
  }
}

function showDashboardView() {
  const loginScreen = document.getElementById("loginScreenView");
  const dashboard = document.getElementById("dashboardAppView");
  if (loginScreen) {
    loginScreen.style.display = "none";
  }
  if (dashboard) {
    dashboard.style.display = "block";
  }
}

function openAuthModal(step = "role") {
  showLoginScreen(step);
}

function closeAuthModal() {
  if (!currentUser) {
    showToast("Please choose your role and enter valid credentials to open the app.", "🔒");
    return;
  }
  showDashboardView();
}

function switchAuthTab(tab) {
  const tabLogin = document.getElementById("tabSwitchLogin");
  const tabSignup = document.getElementById("tabSwitchSignup");
  const loginPanel = document.getElementById("loginFormPanel");
  const signupPanel = document.getElementById("signupFormPanel");

  if (tab === "login") {
    if (tabLogin) tabLogin.classList.add("active");
    if (tabSignup) tabSignup.classList.remove("active");
    if (loginPanel) loginPanel.style.display = "block";
    if (signupPanel) signupPanel.style.display = "none";
  } else {
    if (tabSignup) tabSignup.classList.add("active");
    if (tabLogin) tabLogin.classList.remove("active");
    if (signupPanel) signupPanel.style.display = "block";
    if (loginPanel) loginPanel.style.display = "none";
  }
}

// Event Listeners for Authentication & Screen Transitions
if (userAccountBtn) {
  userAccountBtn.addEventListener("click", () => {
    if (currentUser) {
      if (typeof openProfileModal === "function") {
        openProfileModal();
      } else {
        const pModal = document.getElementById("profileModal");
        if (pModal) pModal.style.display = "flex";
      }
    } else {
      showLoginScreen("role");
    }
  });
}
if (headerLogoutBtn) headerLogoutBtn.addEventListener("click", () => logoutUser());
if (switchUserBtn) switchUserBtn.addEventListener("click", () => logoutUser());
if (closeAuthModalBtn) closeAuthModalBtn.addEventListener("click", closeAuthModal);
if (tabSwitchLogin) tabSwitchLogin.addEventListener("click", () => switchAuthTab("login"));
if (tabSwitchSignup) tabSwitchSignup.addEventListener("click", () => switchAuthTab("signup"));
if (healthCardAuthActionBtn) healthCardAuthActionBtn.addEventListener("click", () => logoutUser());

// Password Eye Toggles
const toggleLoginPassword = document.getElementById("toggleLoginPasswordBtn");
if (toggleLoginPassword) {
  toggleLoginPassword.addEventListener("click", () => {
    const p = document.getElementById("loginPassword");
    if (p) {
      const isPass = p.type === "password";
      p.type = isPass ? "text" : "password";
      toggleLoginPassword.textContent = isPass ? "🙈" : "👁️";
    }
  });
}

const toggleSignupPassword = document.getElementById("toggleSignupPasswordBtn");
if (toggleSignupPassword) {
  toggleSignupPassword.addEventListener("click", () => {
    const p = document.getElementById("signupPassword");
    if (p) {
      const isPass = p.type === "password";
      p.type = isPass ? "text" : "password";
      toggleSignupPassword.textContent = isPass ? "🙈" : "👁️";
    }
  });
}

const toggleResetNewPass = document.getElementById("toggleResetNewPassBtn");
if (toggleResetNewPass) {
  toggleResetNewPass.addEventListener("click", () => {
    const p = document.getElementById("resetNewPassword");
    if (p) {
      const isPass = p.type === "password";
      p.type = isPass ? "text" : "password";
      toggleResetNewPass.textContent = isPass ? "🙈" : "👁️";
    }
  });
}

const toggleResetConfirmPass = document.getElementById("toggleResetConfirmPassBtn");
if (toggleResetConfirmPass) {
  toggleResetConfirmPass.addEventListener("click", () => {
    const p = document.getElementById("resetConfirmPassword");
    if (p) {
      const isPass = p.type === "password";
      p.type = isPass ? "text" : "password";
      toggleResetConfirmPass.textContent = isPass ? "🙈" : "👁️";
    }
  });
}

// Update UI across banner, header, and health card with active user info
function updateUserUI() {
  const ownerSection = document.getElementById("ownerDashboardSection");
  const consultationCard = document.querySelector(".consultation-card");
  const closeBtn = document.getElementById("closeAuthModalBtn");
  const headerAvatar = document.getElementById("headerAvatarIcon");
  const hLogoutBtn = document.getElementById("headerLogoutBtn");
  const allergyShield = document.getElementById("headerAllergyShield");
  const spendingCap = document.getElementById("headerSpendingCap");
  const voiceTitle = document.querySelector(".voice-title");
  const voiceDesc = document.querySelector(".voice-desc");

  if (currentUser) {
    showDashboardView();
    if (headerAccountLabel) headerAccountLabel.textContent = currentUser.name.split(" ")[0];
    if (headerUserName) headerUserName.textContent = currentUser.name;
    if (headerAvatar) headerAvatar.textContent = currentUser.role === "pharmacy_owner" ? "🏪" : "👤";
    const addr = currentUser.address || "Sector 15, Gurgaon";
    const roleLabel = currentUser.role === "pharmacy_owner" ? "Pharmacy Store Owner" : "Verified Patient";
    if (headerUserSubtext) headerUserSubtext.textContent = `${roleLabel} • ${addr}`;
    if (userLocationDisplay) userLocationDisplay.textContent = `📍 ${addr}`;
    if (logoutBtn) logoutBtn.style.display = "inline-flex";
    if (hLogoutBtn) hLogoutBtn.style.display = "inline-flex";
    if (closeBtn) closeBtn.style.display = "flex";

    if (currentUser.role === "pharmacy_owner") {
      if (ownerSection) ownerSection.style.display = "block";
      if (consultationCard) consultationCard.style.display = "none";
      
      // USER REQUIREMENT: In owner dashboard, remove medicine ordering feature & health card icon
      if (tabNavCard) tabNavCard.style.display = "none";
      if (tabNavStores) tabNavStores.style.display = "none";
      if (allergyShield) allergyShield.style.display = "none";
      if (spendingCap) spendingCap.style.display = "none";
      if (chemistShopsBox) chemistShopsBox.style.display = "none";

      // Customize symptom input prompt for owner home remedies
      if (symptomInput) symptomInput.placeholder = "Describe your symptoms to get safe home remedies & guidance...";
      if (voiceTitle) voiceTitle.textContent = "What symptoms are you experiencing? (घरेलू उपचार)";
      if (voiceDesc) voiceDesc.textContent = "Enter your symptoms below to get safe, natural home remedies directly in the chat:";

      // Ensure active view is health check
      switchMainTab("health");

      if (typeof loadOwnerDashboard === "function") loadOwnerDashboard();
    } else {
      if (ownerSection) ownerSection.style.display = "none";
      if (consultationCard) consultationCard.style.display = "block";

      // Restore tabs and badges for normal patients
      if (tabNavCard) tabNavCard.style.display = "";
      if (tabNavStores) tabNavStores.style.display = "";
      if (allergyShield) allergyShield.style.display = "";
      if (spendingCap) spendingCap.style.display = "";

      if (symptomInput) symptomInput.placeholder = "Describe health issue: e.g., 'I have a headache since morning'...";
      if (voiceTitle) voiceTitle.textContent = "Where does it hurt? (क्या तकलीफ है?)";
      if (voiceDesc) voiceDesc.textContent = "Tap the 3D microphone to speak naturally, or pick a common health problem below:";
    }
  } else {
    showLoginScreen("role");
    if (headerAccountLabel) headerAccountLabel.textContent = "Sign In";
    if (headerUserName) headerUserName.textContent = "Select Role & Sign In";
    if (headerUserSubtext) headerUserSubtext.textContent = "Please sign in to access MediConnect";
    if (logoutBtn) logoutBtn.style.display = "none";
    if (hLogoutBtn) hLogoutBtn.style.display = "none";
    if (closeBtn) closeBtn.style.display = "none";
    if (ownerSection) ownerSection.style.display = "none";
    if (tabNavCard) tabNavCard.style.display = "";
    if (tabNavStores) tabNavStores.style.display = "";
  }
}

// Initialize Auth Session from LocalStorage on load
// Flow: [Open App] ➔ [Login Screen] ➔ (Success) ➔ [Dashboard]
async function initAuthSession() {
  const saved = localStorage.getItem("mediconnect_user");
  if (saved) {
    try {
      currentUser = JSON.parse(saved);
      currentUserId = currentUser.id;
      updateUserUI();
      return;
    } catch (e) {
      currentUser = null;
    }
  }

  // If no saved user, land on dedicated Login Screen immediately!
  currentUser = null;
  currentUserId = null;
  updateUserUI();
}

// Submit Login with Role Enforcement
window.submitLogin = async function() {
  const identInput = document.getElementById("loginIdentifier");
  const passInput = document.getElementById("loginPassword");
  const ident = identInput ? identInput.value.trim() : "";
  const pass = passInput ? passInput.value : "";

  if (!ident || !pass) {
    showToast("Please enter your phone number or email and password.", "⚠️");
    return;
  }

  showProgress("Authenticating securely...");
  try {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        identifier: ident,
        password: pass,
        expected_role: selectedAuthRole
      })
    });

    const data = await res.json();
    hideProgress();

    if (!res.ok || !data.success) {
      showToast(data.detail || "Invalid phone/email or password.", "❌");
      return;
    }

    // Save session
    currentUser = data.user;
    currentUserId = data.user.id;
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));

    updateUserUI();
    showDashboardView();

    showToast(`Welcome back, ${currentUser.name}!`, "🎉");
    loadHealthCard();
  } catch (err) {
    hideProgress();
    showToast("Could not log in. Check your server connection.", "⚠️");
  }
};

// Submit Signup
window.submitSignup = async function() {
  const name = signupName ? signupName.value.trim() : "";
  const contact = signupContact ? signupContact.value.trim() : "";
  const email = signupEmail ? signupEmail.value.trim() : "";
  const password = signupPassword ? signupPassword.value : "";
  const storeNameInput = document.getElementById("signupStoreName");
  const storeName = storeNameInput ? storeNameInput.value.trim() : "";
  const address = signupAddress ? signupAddress.value.trim() : "Sector 15, Gurgaon";
  const limit = signupLimit ? (parseFloat(signupLimit.value) || 1500) : 1500;
  const allergiesRaw = signupAllergies ? signupAllergies.value.trim() : "";
  const allergies = allergiesRaw ? allergiesRaw.split(",").map(a => a.trim()).filter(Boolean) : [];

  if (!name || !contact || !password) {
    showToast("Please fill in your name, contact number, and password.", "⚠️");
    return;
  }

  showProgress("Creating encrypted profile & account...");
  try {
    const res = await fetch(`${API_BASE}/auth/signup`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: name,
        contact: contact,
        email: email || null,
        password: password,
        role: selectedAuthRole,
        store_name: selectedAuthRole === "pharmacy_owner" ? (storeName || `${name}'s Medical Store`) : null,
        address: address || "Sector 15, Gurgaon",
        allergies: allergies,
        payment_limit: limit
      })
    });

    const data = await res.json();
    hideProgress();

    if (!res.ok || !data.success) {
      showToast(data.detail || "Signup failed. Please try a different phone or email.", "❌");
      return;
    }

    // Save new user session
    currentUser = data.user;
    currentUserId = data.user.id;
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));

    updateUserUI();
    showDashboardView();

    showToast(`Welcome, ${currentUser.name}! Your account is active.`, "🛡️");
    loadHealthCard();
  } catch (err) {
    hideProgress();
    showToast("Signup request failed. Check server connection.", "⚠️");
  }
};

// Fast 1-Click Demo Logins
window.loginAsDemoCustomer = async function() {
  showProgress("Logging in as Patient Rahul Sharma...");
  try {
    const res = await fetch(`${API_BASE}/auth/demo-login`, { method: "POST" });
    const data = await res.json();
    hideProgress();

    if (res.ok && data.success) {
      currentUser = data.user;
      currentUserId = data.user.id;
      localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
      updateUserUI();
      showDashboardView();
      showToast("Logged in as Rahul Sharma (Demo Patient)!", "⚡");
      loadHealthCard();
    }
  } catch (e) {
    hideProgress();
    showToast("Demo login failed.", "⚠️");
  }
};

window.loginAsDemoOwner = async function() {
  showProgress("Logging in as Pharmacy Owner Ramesh Gupta...");
  try {
    const res = await fetch(`${API_BASE}/auth/owner-demo-login`, { method: "POST" });
    const data = await res.json();
    hideProgress();

    if (res.ok && data.success) {
      currentUser = data.user;
      currentUserId = data.user.id;
      localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
      updateUserUI();
      showDashboardView();
      showToast("Logged in as Ramesh Gupta (Store Owner)!", "🏪");
      loadOwnerDashboard();
    }
  } catch (e) {
    hideProgress();
    showToast("Demo owner login failed.", "⚠️");
  }
};

// Logout user
window.logoutUser = function() {
  localStorage.removeItem("mediconnect_user");
  currentUser = null;
  currentUserId = null;
  updateUserUI();
  showLoginScreen("role");
  showToast("Logged out successfully. Please sign in to continue.", "🚪");
};

if (logoutBtn) {
  logoutBtn.addEventListener("click", logoutUser);
}

// Pharmacy Owner Dashboard Loader
window.loadOwnerDashboard = async function() {
  const container = document.getElementById("ownerInventoryList");
  if (!container) return;

  try {
    const res = await fetch(`${API_BASE}/pharmacy/owner/dashboard/pharm-001`);
    if (res.ok) {
      const data = await res.json();
      const inv = data.inventory || [];
      const stockEl = document.getElementById("ownerStockCount");
      const ordersEl = document.getElementById("ownerPendingOrdersCount");
      if (stockEl) stockEl.textContent = `${inv.length} Medicines`;
      if (ordersEl) ordersEl.textContent = `${(data.orders || []).length} Active Orders`;

      container.innerHTML = inv.slice(0, 6).map(m => `
        <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 12px 16px; display: flex; justify-content: space-between; align-items: center;">
          <div>
            <strong style="font-size: 14px; color: #0f172a;">${m.generic_name}</strong>
            <span style="font-size: 12px; color: #64748b; margin-left: 6px;">(${m.branded_name})</span>
            <div style="font-size: 11px; color: #059669; margin-top: 2px;">Generic: ₹${m.generic_price} | Branded: ₹${m.branded_price}</div>
          </div>
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-weight: 800; font-size: 14px; color: #1e293b;">Stock: <span id="stock-val-${m.id}">${m.stock}</span></span>
            <button class="neu-pill-btn" onclick="updateStockDelta('pharm-001', '${m.id}', 5)" style="padding: 4px 10px; font-size: 12px;">+5</button>
            <button class="neu-pill-btn" onclick="updateStockDelta('pharm-001', '${m.id}', -5)" style="padding: 4px 10px; font-size: 12px;">-5</button>
          </div>
        </div>
      `).join("");
    }
  } catch (e) {}
};

window.updateStockDelta = async function(pharmId, medId, delta) {
  try {
    const res = await fetch(`${API_BASE}/pharmacy/owner/inventory/${pharmId}/update-stock`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ medicine_id: medId, delta: delta })
    });
    if (res.ok) {
      showToast(`Stock updated (${delta > 0 ? '+' : ''}${delta})!`, "📦");
      loadOwnerDashboard();
    }
  } catch (e) {}
};

window.switchToPatientMode = function() {
  selectedAuthRole = "customer";
  if (currentUser) {
    currentUser.role = "customer";
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  }
  updateUserUI();
  showToast("Switched to Patient view.", "👤");
};

// Initialize session upon script execution
initAuthSession();

/* ==========================================================
   ORDERS & BOOKED APPOINTMENTS LOGIC
========================================================== */
if (ordersTabMedsBtn) {
  ordersTabMedsBtn.addEventListener("click", () => {
    ordersTabMedsBtn.classList.add("active");
    ordersTabApptsBtn.classList.remove("active");
    panelOrderedMeds.style.display = "block";
    panelBookedAppts.style.display = "none";
  });
}

if (ordersTabApptsBtn) {
  ordersTabApptsBtn.addEventListener("click", () => {
    ordersTabApptsBtn.classList.add("active");
    ordersTabMedsBtn.classList.remove("active");
    panelBookedAppts.style.display = "block";
    panelOrderedMeds.style.display = "none";
  });
}

if (refreshOrdersBtn) {
  refreshOrdersBtn.addEventListener("click", () => {
    loadUserOrdersAndAppointments();
    showToast("Refreshed orders and appointments", "🔄");
  });
}

async function loadUserOrdersAndAppointments() {
  const uid = currentUser ? currentUser.id : currentUserId;
  
  // 1. Fetch Ordered Medicines
  try {
    const ordersRes = await fetch(`${API_BASE}/pharmacy/orders/user/${uid}`);
    if (ordersRes.ok) {
      const orders = await ordersRes.json();
      ordersCountBadge.textContent = orders.length;
      renderOrdersList(orders);
    } else {
      userOrdersList.innerHTML = `
        <div class="empty-state-card">
          <div class="empty-state-icon">📦</div>
          <div class="empty-state-title">No Orders Placed Yet</div>
          <div class="empty-state-sub">Describe a mild symptom in Triage to have medicines ordered with highest discount from local chemists.</div>
        </div>
      `;
      ordersCountBadge.textContent = "0";
    }
  } catch (e) {
    userOrdersList.innerHTML = `
      <div class="empty-state-card">
        <div class="empty-state-icon">📦</div>
        <div class="empty-state-title">No Orders Recorded</div>
        <div class="empty-state-sub">No recent pharmacy orders found for your profile.</div>
      </div>
    `;
    ordersCountBadge.textContent = "0";
  }

  // 2. Fetch Booked Hospital Appointments
  try {
    const apptsRes = await fetch(`${API_BASE}/emergency/user/${uid}/appointments`);
    if (apptsRes.ok) {
      const appts = await apptsRes.json();
      apptsCountBadge.textContent = appts.length;
      renderAppointmentsList(appts);
    } else {
      userAppointmentsList.innerHTML = `
        <div class="empty-state-card">
          <div class="empty-state-icon">🏥</div>
          <div class="empty-state-title">No Hospital Appointments</div>
          <div class="empty-state-sub">When severe symptoms or emergency SOS is triggered, your hospital ER admission passes will be listed here.</div>
        </div>
      `;
      apptsCountBadge.textContent = "0";
    }
  } catch (e) {
    userAppointmentsList.innerHTML = `
      <div class="empty-state-card">
        <div class="empty-state-icon">🏥</div>
        <div class="empty-state-title">No Appointments Found</div>
        <div class="empty-state-sub">No booked hospital visits recorded yet.</div>
      </div>
    `;
    apptsCountBadge.textContent = "0";
  }
}

function renderOrdersList(orders) {
  if (!orders || orders.length === 0) {
    userOrdersList.innerHTML = `
      <div class="empty-state-card">
        <div class="empty-state-icon">📦</div>
        <div class="empty-state-title">No Previous Orders</div>
        <div class="empty-state-sub">Describe a symptom in Health Check to find generic medicines and order from local stores.</div>
      </div>
    `;
    return;
  }

  userOrdersList.innerHTML = orders.map(ord => {
    const itemsHtml = (ord.items || []).map(item => `
      <div class="order-item-row">
        <span class="order-item-name">💊 ${item.medicine_name || item.name || 'Medicine'}</span>
        <span>Qty: ${item.quantity || 1} • ₹${item.price || item.total_price || 0}</span>
      </div>
    `).join("");

    const dateStr = ord.created_at ? new Date(ord.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'Recent';
    const savingsHtml = ord.savings_amount ? `<span class="order-savings-pill">Saved ₹${Math.round(ord.savings_amount)}</span>` : '';

    return `
      <div class="order-history-card">
        <div class="order-card-header">
          <div>
            <div class="order-id-title">Order #${(ord.order_id || ord.id || '').toString().slice(-8).toUpperCase()}</div>
            <div class="order-pharmacy-name">🏪 ${ord.pharmacy_name || 'Neighborhood Chemist'}</div>
          </div>
          <span class="order-status-pill confirmed">${ord.status || 'CONFIRMED'}</span>
        </div>
        <div class="order-items-list">
          ${itemsHtml || '<div class="order-item-row"><span>Standard Prescription</span></div>'}
        </div>
        <div class="order-card-footer">
          <div class="order-total-price">Total: ₹${Math.round(ord.total_amount || 0)}</div>
          ${savingsHtml}
          <div class="order-time-text">Ordered: ${dateStr}</div>
        </div>
      </div>
    `;
  }).join("");
}

function renderAppointmentsList(appts) {
  if (!appts || appts.length === 0) {
    userAppointmentsList.innerHTML = `
      <div class="empty-state-card">
        <div class="empty-state-icon">🏥</div>
        <div class="empty-state-title">No Booked Appointments</div>
        <div class="empty-state-sub">When severe symptoms or emergency SOS is triggered, your priority ER passes will appear here.</div>
      </div>
    `;
    return;
  }

  userAppointmentsList.innerHTML = appts.map(apt => {
    const type = (apt.appointment_type || apt.event_type || '').toLowerCase();
    const isEr = type.includes('emergency') || type.includes('er') || (apt.token_id || '').startsWith('ER');
    const badgeClass = isEr ? 'er' : 'clinic';
    const typeLabel = isEr ? '🚨 ER Priority Admission' : '🩺 Specialist Consultation';
    const dateStr = apt.created_at ? new Date(apt.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'Today';

    return `
      <div class="appointment-history-card ${badgeClass}">
        <div class="appt-card-header">
          <div>
            <div class="appt-hospital-name">🏥 ${apt.hospital_name || 'Metro Emergency Hospital'}</div>
            <div style="font-size: 13px; color: #475569; margin-top: 3px;">📍 ${apt.hospital_address || 'Sector 15 / Cyber City'}</div>
          </div>
          <span class="appt-type-badge ${badgeClass}">${typeLabel}</span>
        </div>
        <div class="appt-token-box">
          <span class="appt-token-title">Token / Pass ID:</span>
          <span class="appt-token-num">${apt.token_id || 'ER-PASS'}</span>
        </div>
        <div class="appt-card-footer">
          <span>Status: <strong>${apt.status || 'RESERVED'}</strong></span>
          <span>${dateStr}</span>
        </div>
      </div>
    `;
  }).join("");
}

/* ==========================================================
   LOCATION SELECTOR MODAL LOGIC (GPS & MANUAL)
========================================================== */
function openLocationModal() {
  if (currentUser && currentUser.address) {
    manualAddressInput.value = currentUser.address;
  }
  gpsDetectStatus.style.display = "none";
  locationModal.style.display = "flex";
}

function closeLocationModal() {
  locationModal.style.display = "none";
}

if (openLocationModalBtn) openLocationModalBtn.addEventListener("click", openLocationModal);
if (closeLocationModalBtn) closeLocationModalBtn.addEventListener("click", closeLocationModal);

// Auto-detect location using browser GPS / Geolocation
if (btnAutoDetectGps) {
  btnAutoDetectGps.addEventListener("click", () => {
    gpsDetectStatus.className = "gps-status-msg loading";
    gpsDetectStatus.textContent = "🛰️ Pinpointing GPS coordinates via satellite...";
    gpsDetectStatus.style.display = "block";

    if (!navigator.geolocation) {
      // Fallback
      fallbackLocationDetect();
      return;
    }

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        gpsDetectStatus.className = "gps-status-msg success";
        gpsDetectStatus.textContent = `📍 Located at (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E). Updating profile...`;

        const detectedAddr = `Current Location (${lat.toFixed(4)}, ${lng.toFixed(4)}), Gurgaon`;
        await saveLocationToProfile(detectedAddr, lat, lng);
        setTimeout(closeLocationModal, 1200);
      },
      (err) => {
        // Fallback for simulation/permission denied
        fallbackLocationDetect();
      },
      { timeout: 6000 }
    );
  });
}

function fallbackLocationDetect() {
  const lat = 28.4595;
  const lng = 77.0266;
  gpsDetectStatus.className = "gps-status-msg success";
  gpsDetectStatus.textContent = `📍 Detected via Maps: Sector 15, Gurgaon (${lat}° N, ${lng}° E)`;
  saveLocationToProfile("Sector 15, Near Star Mall, Gurgaon", lat, lng);
  setTimeout(closeLocationModal, 1200);
}

window.saveManualLocation = async function() {
  const addr = manualAddressInput.value.trim();
  const city = manualCityInput.value.trim();
  const pin = manualPincodeInput.value.trim();
  const fullAddr = `${addr}, ${city} - ${pin}`;
  await saveLocationToProfile(fullAddr);
  closeLocationModal();
};

async function saveLocationToProfile(newAddress, lat = 28.4595, lng = 77.0266) {
  const uid = currentUser ? currentUser.id : currentUserId;
  try {
    const res = await fetch(`${API_BASE}/records/user/${uid}/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        address: newAddress,
        latitude: lat,
        longitude: lng
      })
    });
    if (res.ok) {
      if (currentUser) {
        currentUser.address = newAddress;
        currentUser.latitude = lat;
        currentUser.longitude = lng;
        localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
      }
      updateUserUI();
      showToast(`Location updated to: ${newAddress}`, "📍");
    } else {
      showToast("Could not update location on server.", "⚠️");
    }
  } catch (e) {
    if (currentUser) {
      currentUser.address = newAddress;
      localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
      updateUserUI();
    }
    showToast(`Location set: ${newAddress}`, "📍");
  }
}

/* ==========================================================
   PATIENT PROFILE MODAL LOGIC
========================================================== */
async function openProfileModal() {
  const uid = currentUser ? currentUser.id : currentUserId;
  profileModal.style.display = "flex";
  profileViewCard.style.display = "flex";
  profileEditForm.style.display = "none";

  try {
    const res = await fetch(`${API_BASE}/records/user/${uid}`);
    if (res.ok) {
      const u = await res.json();
      profileViewName.textContent = u.name || "Patient";
      profileViewPhone.textContent = u.contact_phone || "Not provided";
      profileViewEmail.textContent = u.email || `${(u.name || "user").toLowerCase().replace(/\s+/g, '')}@health.in`;
      profileViewAddress.textContent = u.address || "Sector 15, Gurgaon";
      profileViewCoords.textContent = `${u.latitude || 28.4595}° N, ${u.longitude || 77.0266}° E`;
      profileViewLimit.textContent = `₹${Math.round(u.payment_limit || 1500)} per transaction`;
      profileViewCreatedAt.textContent = u.created_at ? new Date(u.created_at).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' }) : "Active Verified";

      // Allergies list
      if (u.allergies && u.allergies.length > 0) {
        profileViewAllergies.innerHTML = u.allergies.map(a => `<span class="prof-allergy-tag">🛡️ ${a} Blocked</span>`).join("");
      } else {
        profileViewAllergies.innerHTML = `<span style="font-size:13px; color:#64748b;">No known allergies</span>`;
      }

      // Emergency contacts
      if (u.emergency_contacts && u.emergency_contacts.length > 0) {
        profileViewContacts.innerHTML = u.emergency_contacts.map(c => `<span class="prof-contact-tag">📞 ${c.name || 'Emergency'}: ${c.phone}</span>`).join("");
      } else {
        profileViewContacts.innerHTML = `<span class="prof-contact-tag">📞 Family SOS: +91 98111 22334</span>`;
      }

      // Prepopulate edit form
      editProfileName.value = u.name || "";
      editProfileContact.value = u.contact_phone || "";
      editProfileEmail.value = u.email || "";
      editProfileAddress.value = u.address || "";
      editProfileLimit.value = Math.round(u.payment_limit || 1500);
    }
  } catch (e) {
    showToast("Could not fetch profile details.", "⚠️");
  }
}

function closeProfileModal() {
  profileModal.style.display = "none";
}

if (openProfileBtn) openProfileBtn.addEventListener("click", openProfileModal);
if (closeProfileModalBtn) closeProfileModalBtn.addEventListener("click", closeProfileModal);

if (btnToggleEditProfile) {
  btnToggleEditProfile.addEventListener("click", () => {
    profileViewCard.style.display = "none";
    profileEditForm.style.display = "block";
  });
}

if (btnCancelEditProfile) {
  btnCancelEditProfile.addEventListener("click", () => {
    profileEditForm.style.display = "none";
    profileViewCard.style.display = "flex";
  });
}

window.saveProfileUpdates = async function() {
  const uid = currentUser ? currentUser.id : currentUserId;
  const updatedData = {
    name: editProfileName.value.trim(),
    contact_phone: editProfileContact.value.trim(),
    email: editProfileEmail.value.trim(),
    address: editProfileAddress.value.trim(),
    payment_limit: parseFloat(editProfileLimit.value) || 1500
  };

  try {
    const res = await fetch(`${API_BASE}/records/user/${uid}/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(updatedData)
    });
    if (res.ok) {
      const data = await res.json();
      currentUser = { ...currentUser, ...updatedData };
      localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
      updateUserUI();
      showToast("Profile details updated successfully!", "✅");
      openProfileModal(); // Refresh view
    } else {
      showToast("Failed to save profile updates.", "❌");
    }
  } catch (e) {
    showToast("Error updating profile.", "⚠️");
  }
};
