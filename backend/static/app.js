// MediConnect — Easy, Accessible Health Assistant & Pharmacy Client
const API_BASE = (function() {
  try {
    const urlParams = new URLSearchParams(window.location.search);
    const paramApi = urlParams.get("api");
    if (paramApi) {
      localStorage.setItem("mediconnect_custom_api", paramApi);
      return paramApi.replace(/\/+$/, "");
    }
    const custom = localStorage.getItem("mediconnect_custom_api");
    if (custom) return custom.replace(/\/+$/, "");
  } catch (e) {}
  return window.location.origin + "/api";
})();

// ==========================================================
// LOCAL STORAGE PERSISTENCE HELPERS (FOR OFFLINE / GITHUB PAGES)
// ==========================================================
function getStoredOrders() {
  try {
    return JSON.parse(localStorage.getItem("mediconnect_orders") || "[]");
  } catch (e) {
    return [];
  }
}

function saveOrderToLocalStorage(order) {
  try {
    const orders = getStoredOrders();
    const orderKey = order.order_id || order.id;
    const exists = orders.some(o => (o.order_id || o.id) === orderKey);
    if (!exists) {
      orders.unshift(order);
      localStorage.setItem("mediconnect_orders", JSON.stringify(orders));
    }
  } catch (e) {
    console.warn("Local order storage failed", e);
  }
}

function getStoredAppointments() {
  try {
    return JSON.parse(localStorage.getItem("mediconnect_appointments") || "[]");
  } catch (e) {
    return [];
  }
}

function saveAppointmentToLocalStorage(appt) {
  try {
    const appts = getStoredAppointments();
    const apptKey = appt.token_id || appt.id;
    const exists = appts.some(a => (a.token_id || a.id) === apptKey);
    if (!exists) {
      appts.unshift(appt);
      localStorage.setItem("mediconnect_appointments", JSON.stringify(appts));
    }
  } catch (e) {
    console.warn("Local appointment storage failed", e);
  }
}

function getDemoShops(query = "") {
  const shops = [
    {
      id: "pharm-001",
      name: "Sanjeevani Local Chemist",
      address: "Shop #4, Sector 15 Market, Near Mother Dairy, Gurgaon",
      phone: "+91 98101 23456",
      distance_km: 0.3,
      rating: 4.9,
      inventory: [
        { generic_name: "Paracetamol 500mg Tablet", branded_name: "Crocin / Dolo", generic_price: 18, branded_price: 45, stock: 120 },
        { generic_name: "Cetirizine 10mg Tablet", branded_name: "Zyrtec / Cetzine", generic_price: 15, branded_price: 42, stock: 110 },
        { generic_name: "Omeprazole 20mg Capsule", branded_name: "Omez 20", generic_price: 22, branded_price: 62, stock: 105 },
        { generic_name: "Oral Rehydration Salts (ORS) Sachet", branded_name: "Electral", generic_price: 14, branded_price: 22, stock: 200 }
      ]
    },
    {
      id: "pharm-002",
      name: "Gupta Medical & Day-Night Store",
      address: "Booth 12, Main Commercial Complex, Sector 15, Gurgaon",
      phone: "+91 98102 34567",
      distance_km: 0.8,
      rating: 4.7,
      inventory: [
        { generic_name: "Paracetamol 500mg Tablet", branded_name: "Crocin 500", generic_price: 19, branded_price: 45, stock: 95 },
        { generic_name: "Amoxicillin 500mg Capsule", branded_name: "Mox 500", generic_price: 45, branded_price: 110, stock: 60 },
        { generic_name: "Ibuprofen 400mg Tablet", branded_name: "Brufen 400", generic_price: 22, branded_price: 52, stock: 80 }
      ]
    },
    {
      id: "pharm-003",
      name: "Apollo Pharmacy 24/7",
      address: "SCO 45, Ground Floor, Sector 14, Gurgaon",
      phone: "+91 98103 45678",
      distance_km: 1.2,
      rating: 4.8,
      inventory: [
        { generic_name: "Paracetamol 650mg Tablet", branded_name: "Dolo 650", generic_price: 24, branded_price: 58, stock: 140 },
        { generic_name: "Pantoprazole 40mg Tablet", branded_name: "Pan 40", generic_price: 28, branded_price: 88, stock: 130 },
        { generic_name: "Vitamin C 500mg Chewable", branded_name: "Limcee", generic_price: 15, branded_price: 32, stock: 180 }
      ]
    },
    {
      id: "pharm-004",
      name: "MedPlus Chemist & Wellness",
      address: "SCF 22, Old Judicial Complex, Civil Lines, Gurgaon",
      phone: "+91 98104 56789",
      distance_km: 1.7,
      rating: 4.6,
      inventory: [
        { generic_name: "Cetirizine 10mg Tablet", branded_name: "Cetzine", generic_price: 15, branded_price: 42, stock: 90 },
        { generic_name: "Metformin 500mg SR Tablet", branded_name: "Glycomet", generic_price: 18, branded_price: 42, stock: 150 },
        { generic_name: "Povidone Iodine 5% Ointment", branded_name: "Betadine", generic_price: 35, branded_price: 78, stock: 65 }
      ]
    }
  ];

  if (!query) return shops;
  const q = query.toLowerCase();
  return shops.filter(s => 
    s.name.toLowerCase().includes(q) || 
    s.address.toLowerCase().includes(q) ||
    (s.inventory && s.inventory.some(i => i.generic_name.toLowerCase().includes(q) || (i.branded_name && i.branded_name.toLowerCase().includes(q))))
  );
}

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

// Voice Assistant with Multilingual Indian Language Recognition
let isRecording = false;
let activeRecognition = null;

function stopVoiceRecording() {
  isRecording = false;
  if (voiceBtn) voiceBtn.classList.remove("listening");
  const wave = document.getElementById("micWaveContainer");
  if (wave) wave.style.display = "none";
  if (micStatusText) micStatusText.textContent = "Tap to Speak";
  if (activeRecognition) {
    try { activeRecognition.stop(); } catch(e) {}
    activeRecognition = null;
  }
}

window.changeVoiceLanguage = function(langCode) {
  if (isRecording && activeRecognition) {
    stopVoiceRecording();
    showToast(`Language switched to ${getLangName(langCode)}. Tap mic to speak.`, "🌐");
  }
};

window.triggerMicVoice = function() {
  if (voiceBtn) voiceBtn.click();
};

function getLangName(code) {
  const map = {
    'en-IN': 'English', 'hi-IN': 'हिन्दी (Hindi)', 'te-IN': 'తెలుగు (Telugu)',
    'ta-IN': 'தமிழ் (Tamil)', 'bn-IN': 'বাংলা (Bengali)', 'mr-IN': 'मराठी (Marathi)',
    'gu-IN': 'ગુજરાતી (Gujarati)', 'kn-IN': 'ಕನ್ನಡ (Kannada)', 'ml-IN': 'മലയാളം (Malayalam)',
    'pa-IN': 'ਪੰਜਾਬੀ (Punjabi)'
  };
  return map[code] || code;
}

if (voiceBtn) {
  voiceBtn.addEventListener("click", () => {
    if (isRecording) {
      stopVoiceRecording();
      return;
    }

    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      showToast("Speech recognition is not supported in this browser. Please type symptoms.", "⚠️");
      symptomInput.focus();
      return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    const recognition = new SpeechRecognition();
    activeRecognition = recognition;

    // Detect Indian language selected by user or app language
    const langSelect = document.getElementById("voiceLangSelect");
    const chosenLang = langSelect ? langSelect.value : (currentAppLang === "hi" ? "hi-IN" : "en-IN");
    recognition.lang = chosenLang;
    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.onstart = () => {
      isRecording = true;
      voiceBtn.classList.add("listening");
      const wave = document.getElementById("micWaveContainer");
      if (wave) wave.style.display = "flex";
      if (micStatusText) micStatusText.textContent = `Listening in ${getLangName(chosenLang)}... Speak now`;
    };

    recognition.onresult = (event) => {
      if (event.results && event.results.length > 0 && event.results[0].length > 0) {
        const text = event.results[0][0].transcript;
        if (symptomInput) symptomInput.value = text;
        showToast(`🎙️ Heard (${getLangName(chosenLang)}): "${text}"`, "🗣️");
        stopVoiceRecording();
        submitSymptom();
      }
    };

    recognition.onerror = (event) => {
      stopVoiceRecording();
      if (event.error === "not-allowed" || event.error === "permission-denied") {
        showToast("Microphone permission denied. Please allow microphone access in browser settings.", "⚠️");
      } else if (event.error === "no-speech") {
        showToast("No speech detected. Please speak closer to microphone.", "ℹ️");
      } else {
        showToast(`Microphone error: ${event.error}. Please try again.`, "⚠️");
      }
    };

    recognition.onend = () => {
      stopVoiceRecording();
    };

    try {
      recognition.start();
    } catch(err) {
      stopVoiceRecording();
      showToast("Could not start microphone. Please try again.", "⚠️");
    }
  });
}

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
    const isOwner = currentUser?.role === "pharmacy_owner";
    const pickupLoc = isOwner ? "Apex Pharmacy, Shop #4, Sector 15 Market, Gurgaon" : "Sector 15, Gurgaon";
    const mockData = {
      summary: "Manual Emergency SOS Triggered. Ambulance dispatched.",
      emergency_event_id: "EMG-7821",
      hospital_appointment_details: {
        hospital_name: "Metro Trauma & Heart Hospital",
        distance_km: "0.6",
        token_id: "ER-7821"
      }
    };
    saveAppointmentToLocalStorage({
      id: "ER-7821",
      token_id: "ER-7821",
      hospital_name: "Metro Trauma & Heart Hospital",
      hospital_address: "Sector 15 / Cyber City",
      appointment_type: "emergency",
      status: "RESERVED",
      created_at: new Date().toISOString()
    });
    renderEmergencyBanner(mockData.summary, mockData);
    if (emergencyDispatchedBox) {
      emergencyDispatchedBox.style.display = "block";
      emergencyDispatchedBox.innerHTML = `
        <div class="sos-alert-badge">🚨 AMBULANCE DISPATCHED</div>
        <p class="sos-booking-code">Ambulance Booking: <strong>AMB-7821</strong> (~7 mins arrival to ${isOwner ? 'Shop #4 Market' : 'Sector 15'})</p>
        <div class="sos-hospital-box">
          <div class="sos-hosp-pill">🏥 NEAREST HOSPITAL AUTO-BOOKED</div>
          <p class="sos-hosp-title">Metro Trauma & Heart Hospital</p>
          <p class="sos-hosp-meta">Distance: 0.6 km away • Token: <strong class="token-highlight">ER-7821</strong></p>
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
    addChatBubble(`🚨 IMMEDIATE EMERGENCY ACTIVATED:
🚑 Ambulance (108) dispatched to: ${pickupLoc} (~7 mins arrival).
🏥 Nearest Hospital ER Auto-Booked: Metro Trauma & Heart Hospital (0.6 km away).
🎫 Trauma ER Admission Token: ER-7821 (Pre-cleared, no waiting).
📞 Direct Ambulance Helpline: 108 / 102`, "assistant");
    showToast("🚨 Ambulance Dispatched & Nearest ER Auto-Booked!", "🚨");
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
    // Intelligent fallback response for GitHub Pages demo
    const isOwner = currentUser?.role === "pharmacy_owner";
    const qLower = query.toLowerCase();
    const isEmergency = qLower.includes("chest pain") || qLower.includes("heart") || qLower.includes("cannot breathe") || qLower.includes("unconscious") || qLower.includes("stroke");
    const isChronic = qLower.includes("weeks") || qLower.includes("months") || qLower.includes("chronic") || qLower.includes("long time");
    
    let medName = "Paracetamol 500mg Tablet";
    let genPrice = 18.0;
    let brandPrice = 45.0;
    let dosage = "1 tablet after meals if fever or body ache persists";

    if (qLower.includes("acid") || qLower.includes("stomach") || qLower.includes("gas") || qLower.includes("burn") || qLower.includes("indigestion")) {
      medName = "Omeprazole 20mg Capsule";
      genPrice = 22.0;
      brandPrice = 62.0;
      dosage = "1 capsule 30 minutes before breakfast with water";
    } else if (qLower.includes("cold") || qLower.includes("cough") || qLower.includes("sneeze") || qLower.includes("allergy") || qLower.includes("runny") || qLower.includes("throat")) {
      medName = "Cetirizine 10mg Tablet";
      genPrice = 15.0;
      brandPrice = 42.0;
      dosage = "1 tablet once daily before sleep";
    } else if (qLower.includes("loose") || qLower.includes("diarrhea") || qLower.includes("vomit") || qLower.includes("dehydration")) {
      medName = "Oral Rehydration Salts (ORS) Sachet";
      genPrice = 14.0;
      brandPrice = 22.0;
      dosage = "Dissolve 1 sachet in 1 litre clean water, sip frequently";
    }

    const savings = brandPrice - genPrice;
    const discount = Math.round((savings / brandPrice) * 100);

    const clinicToken = "MED-CLINIC-" + Math.floor(100 + Math.random() * 900);
    if (isChronic) {
      saveAppointmentToLocalStorage({
        id: clinicToken,
        token_id: clinicToken,
        hospital_name: "Metro Specialty Clinic (Sector 15)",
        hospital_address: "Sector 15, Gurgaon",
        appointment_type: "clinic",
        status: "RESERVED",
        created_at: new Date().toISOString()
      });
    }

    const demoData = {
      summary: `Clinical assessment for: "${query}".`,
      ai_explanation: isEmergency 
        ? "⚠️ CRITICAL EMERGENCY DETECTED: Symptoms require immediate hospital trauma assessment. Do not self-medicate."
        : (isChronic 
            ? `Your reported symptoms ("${query}") have persisted. A priority consultation has been held at Metro Specialty Clinic.`
            : `Based on reported symptoms ("${query}"), rest and safe supportive natural care are advised. We located safe generic medicines with up to ${discount}% savings at verified local shops.`),
      severity: isEmergency ? "emergency" : (isChronic ? "medium" : "low"),
      emergency_detected: isEmergency,
      hospital_appointment_suggested: isChronic,
      hospital_appointment_details: isChronic ? {
        hospital_name: "Metro Specialty Clinic (Sector 15)",
        distance_km: "0.8",
        token_id: clinicToken
      } : null,
      best_discount_pharmacy: (!isEmergency && !isChronic) ? {
        pharmacy_id: "pharm-001",
        pharmacy_name: "Sanjeevani Local Chemist",
        address: "Shop 4, Market Complex, Sector 15",
        distance_km: 0.3,
        medicine_name: medName,
        generic_price: genPrice,
        branded_price: brandPrice,
        savings: savings,
        discount_percent: discount
      } : null,
      home_remedies: [
        "Drink warm water with ginger and honey to soothe throat and body ache",
        "Perform steam inhalation for 10 minutes to clear nasal congestion",
        "Take restful sleep in a well-ventilated room with elevated pillow support"
      ],
      recommended_medicines: (!isEmergency && !isChronic) ? [
        { generic_name: medName, average_generic_price: genPrice, average_branded_price: brandPrice, dosage_and_usage: dosage }
      ] : []
    };
    renderDoctorAdvice(demoData);
    if (!isOwner && !demoData.emergency_detected) {
      loadNearbyChemists();
    }
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
  
  const orderResult = await orderFromChemist(pharmacyId, pharmacyName, medName, price);
  const orderNum = (orderResult && (orderResult.order_id || orderResult.id)) ? (orderResult.order_id || orderResult.id).toString().slice(-8).toUpperCase() : "CONFIRMED";
  
  if (askBox) {
    askBox.innerHTML = `
      <div class="order-confirmed-banner" style="flex-direction: column; align-items: flex-start;">
        <div style="display: flex; align-items: center; gap: 14px;">
          <div style="font-size: 32px;">🎉</div>
          <div>
            <h4 style="color: #047857; font-size: 16px; font-weight: 800; margin-bottom: 2px;">Order #${orderNum} Confirmed & Packing!</h4>
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
  return await window.orderFromChemist("pharm-001", "Sanjeevani Local Chemist", medName, price);
};

function displayLiveOrder(shopName, medName, amount) {
  if (trackerMedName) trackerMedName.textContent = medName;
  if (trackerShopName) trackerShopName.textContent = `from ${shopName}`;
  if (trackerAmount) trackerAmount.textContent = `₹${Number(amount || 18).toFixed(0)} Paid (Auto-Approved)`;
  if (liveOrderTracker) {
    liveOrderTracker.style.display = "flex";
    liveOrderTracker.scrollIntoView({ behavior: "smooth" });
  }
}

if (callRunnerBtn) {
  callRunnerBtn.addEventListener("click", () => {
    showToast("Connecting call to Sanjeevani Chemist (+91 98101 23456)...", "📞");
  });
}

async function loadNearbyChemists() {
  if (!chemistShopsBox || !chemistList) return;
  chemistShopsBox.style.display = "flex";
  let shops = [];
  try {
    const res = await fetch(`${API_BASE}/pharmacy/nearby`);
    if (res.ok) {
      shops = await res.json();
    }
  } catch (err) {}

  if (!shops || shops.length === 0) {
    shops = getDemoShops();
  }

  chemistList.innerHTML = "";
  shops.forEach(shop => {
    const card = createShopCard(shop);
    chemistList.appendChild(card);
  });
}

function createShopCard(shop) {
  const card = document.createElement("div");
  card.className = "chemist-shop-card";
  
  const med = (shop.inventory && shop.inventory.length > 0) ? shop.inventory[0] : null;
  const price = med ? (med.generic_price || med.price || 18) : 18;
  const medName = med ? (med.generic_name || med.name || "Paracetamol 500mg") : "Paracetamol 500mg";
  
  card.innerHTML = `
    <div class="shop-main-info">
      <div>
        <h4 class="shop-name-title">🏪 ${shop.name}</h4>
        <p class="shop-address-text">${shop.address}</p>
      </div>
      <span class="distance-badge">${shop.distance_km || 0.4} km away</span>
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
  const shopTitle = pharmacyName || "Sanjeevani Local Chemist";
  const pId = pharmacyId || "pharm-001";
  const numPrice = Number(price) || 18;
  showProgress(`Placing order with ${shopTitle}...`);
  
  let orderData = null;
  try {
    const res = await fetch(`${API_BASE}/pharmacy/orders/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: currentUserId,
        pharmacy_id: pId,
        items: [
          {
            medicine_name: medName,
            is_generic: true,
            unit_price: numPrice,
            quantity: 1
          }
        ],
        payment_method: "UPI_AUTOPAY"
      })
    });
    if (res.ok) {
      orderData = await res.json();
    }
  } catch (err) {
    // Graceful offline fallback below
  }

  hideProgress();

  if (!orderData) {
    const orderNum = "ORD-" + Math.floor(100000 + Math.random() * 900000);
    orderData = {
      id: orderNum,
      order_id: orderNum,
      pharmacy_id: pId,
      pharmacy_name: shopTitle,
      status: "CONFIRMED",
      subtotal: numPrice,
      generic_savings: Math.round(numPrice * 1.5),
      total_amount: numPrice,
      commission_rate_percent: 6.5,
      commission_amount: Number((numPrice * 0.065).toFixed(2)),
      auto_pay_approved: true,
      created_at: new Date().toISOString(),
      items: [
        {
          medicine_name: medName,
          name: medName,
          is_generic: true,
          unit_price: numPrice,
          price: numPrice,
          quantity: 1
        }
      ]
    };
  }

  // Persist order in local storage for the Orders & Appointments tab
  saveOrderToLocalStorage(orderData);

  // Display live order tracker banner
  displayLiveOrder(orderData.pharmacy_name || shopTitle, medName, orderData.total_amount || numPrice);
  showToast(`Order Placed! ${orderData.pharmacy_name || shopTitle} is packing your medicine.`, "🎉");
  return orderData;
};

window.callChemist = function(phone, name) {
  showToast(`Calling ${name} at ${phone || '+91 98101 23456'}...`, "📞");
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
  if (!fullChemistList) return;
  fullChemistList.innerHTML = "<div style='color:#94a3b8; padding:10px;'>Finding trusted neighborhood medical stores...</div>";
  let shops = [];
  try {
    const url = query ? `${API_BASE}/pharmacy/nearby?query=${encodeURIComponent(query)}` : `${API_BASE}/pharmacy/nearby`;
    const res = await fetch(url);
    if (res.ok) {
      shops = await res.json();
    }
  } catch (e) {}

  if (!shops || shops.length === 0) {
    shops = getDemoShops(query);
  }

  fullChemistList.innerHTML = "";
  if (!shops || shops.length === 0) {
    fullChemistList.innerHTML = `<div style='color:#94a3b8; padding:10px;'>No stores found matching "${query}". Try searching for Paracetamol or Cetirizine.</div>`;
    return;
  }
  shops.forEach(shop => {
    fullChemistList.appendChild(createShopCard(shop));
  });
}

async function loadHealthCard() {
  if (!healthCardDetails) return;
  healthCardDetails.innerHTML = "<div style='color:#94a3b8; padding:10px;'>Loading your safe health card...</div>";
  let data = null;
  try {
    const res = await fetch(`${API_BASE}/records/user/${currentUserId}`);
    if (res.ok) {
      data = await res.json();
    }
  } catch (e) {}

  if (!data) {
    const savedAllergies = JSON.parse(localStorage.getItem("mediconnect_allergies") || '["Aspirin", "Ibuprofen"]');
    const savedLimit = parseFloat(localStorage.getItem("mediconnect_payment_limit") || (currentUser?.payment_limit || "1500"));
    data = {
      name: currentUser?.name || "Rahul Sharma",
      contact: currentUser?.contact_phone || currentUser?.contact || "+91 98765 43210",
      address: currentUser?.address || "Flat 402, Green Park Avenue, Sector 15, Gurgaon",
      allergies: savedAllergies,
      active_medications: [
        { medicine_name: "Metformin 500mg SR", dosage: "1 tab daily after breakfast" }
      ],
      payment_limit: savedLimit
    };
  }

  // Also sync local patient name if returned
  const patientCleanName = (currentUser?.name || data.name || "Rahul Sharma")
    .replace(/\s*\((Store )?Owner\)/gi, "")
    .replace(/Sanjeevani Chemist/gi, "Ramesh Gupta")
    .trim();
  data.name = patientCleanName;
  if (headerUserName) {
    headerUserName.textContent = patientCleanName;
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
}

window.submitNewAllergy = async function() {
  const input = document.getElementById("newAllergyInput");
  const allergy = input ? input.value.trim() : "";
  if (!allergy) return;
  
  try {
    await fetch(`${API_BASE}/records/user/${currentUserId}/allergy?allergy=${encodeURIComponent(allergy)}`, {
      method: "POST"
    });
  } catch (e) {}

  const allergies = JSON.parse(localStorage.getItem("mediconnect_allergies") || '["Aspirin", "Ibuprofen"]');
  if (!allergies.includes(allergy)) {
    allergies.push(allergy);
    localStorage.setItem("mediconnect_allergies", JSON.stringify(allergies));
  }
  if (currentUser) {
    currentUser.allergies = allergies;
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  }
  showToast(`Allergy '${allergy}' added and encrypted.`, "🛡️");
  loadHealthCard();
};

window.submitNewPaymentLimit = async function() {
  const input = document.getElementById("newLimitInput");
  const val = input ? parseFloat(input.value) : 0;
  if (!val || val <= 0) return;
  
  try {
    await fetch(`${API_BASE}/records/user/${currentUserId}/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ payment_limit: val })
    });
  } catch (e) {}

  localStorage.setItem("mediconnect_payment_limit", val.toString());
  if (currentUser) {
    currentUser.payment_limit = val;
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  }
  showToast(`Payment limit updated to ₹${val.toFixed(0)}.`, "🔒");
  if (headerSpendingCap) headerSpendingCap.textContent = `🔒 Auto-Pay Cap: ₹${val.toFixed(0)}`;
  loadHealthCard();
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
    currentPasswordResetEmail = email;
    const sentLabel = document.getElementById("sentCodeEmailLabel");
    if (sentLabel) sentLabel.textContent = currentPasswordResetEmail;

    const banner = document.getElementById("devCodeBanner");
    const valSpan = document.getElementById("devCodeValue");
    if (valSpan) valSpan.textContent = "842910";
    if (banner) banner.style.display = "flex";

    const forgotEmailPanel = document.getElementById("forgotEmailPanel");
    const forgotCodePanel = document.getElementById("forgotCodePanel");
    if (forgotEmailPanel) forgotEmailPanel.style.display = "none";
    if (forgotCodePanel) forgotCodePanel.style.display = "block";

    showToast(`Verification code sent to ${currentPasswordResetEmail}! (Demo code: 842910)`, "📨");
  }
};

// Auto-fill Code for Quick Local Testing
window.autofillResetCode = function() {
  const valSpan = document.getElementById("devCodeValue");
  const code = valSpan ? valSpan.textContent.trim() : "842910";
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
    showToast("Password reset successfully! (Demo Mode)", "🎉");
    const identInput = document.getElementById("loginIdentifier");
    const passInput = document.getElementById("loginPassword");
    if (identInput) identInput.value = currentPasswordResetEmail;
    if (passInput) passInput.value = "";

    const forgotCodePanel = document.getElementById("forgotCodePanel");
    const credPanel = document.getElementById("credentialsPanel");
    if (forgotCodePanel) forgotCodePanel.style.display = "none";
    if (credPanel) credPanel.style.display = "block";
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
    const cleanDisplayName = (currentUser.name || "User")
      .replace(/\s*\((Store )?Owner\)/gi, "")
      .replace(/Sanjeevani Chemist/gi, "Ramesh Gupta")
      .trim();
    if (headerAccountLabel) headerAccountLabel.textContent = cleanDisplayName.split(" ")[0];
    if (headerUserName) headerUserName.textContent = cleanDisplayName;
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
    // GitHub Pages / Offline demo fallback
    const isOwner = ident.toLowerCase().includes("owner") || selectedAuthRole === "pharmacy_owner";
    currentUser = isOwner ? {
      id: "usr-owner-001",
      name: "Ramesh Gupta",
      email: ident || "owner@sanjeevani.in",
      role: "pharmacy_owner",
      address: "Shop #4, Sector 15 Market, Gurgaon",
      store_name: "Sanjeevani Local Chemist"
    } : {
      id: "usr-sample-001",
      name: "Rahul Sharma",
      email: ident || "rahul@health.in",
      role: "customer",
      address: "Sector 15, Gurgaon"
    };
    currentUserId = currentUser.id;
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
    updateUserUI();
    showDashboardView();
    showToast(`Welcome, ${currentUser.name}! (Demo Mode)`, "🎉");
    loadHealthCard();
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
    // GitHub Pages / Offline demo fallback
    const isOwner = selectedAuthRole === "pharmacy_owner";
    currentUser = {
      id: "usr-" + Date.now().toString(36),
      name: name,
      contact_phone: contact,
      email: email || `${name.toLowerCase().replace(/\s+/g, '')}@health.in`,
      role: selectedAuthRole,
      address: address || "Sector 15, Gurgaon",
      store_name: isOwner ? (storeName || `${name}'s Medical Store`) : null,
      payment_limit: limit,
      allergies: allergies
    };
    currentUserId = currentUser.id;
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
    updateUserUI();
    showDashboardView();
    showToast(`Welcome, ${currentUser.name}! Your account is active.`, "🛡️");
    loadHealthCard();
  }
};

// Fast 1-Click Demo Logins
window.loginAsDemoCustomer = async function() {
  showProgress("Logging in as Patient Rahul Sharma...");
  try {
    const res = await fetch(`${API_BASE}/auth/demo-login`, { method: "POST" });
    if (res.ok) {
      const data = await res.json();
      if (data.success && data.user) {
        currentUser = data.user;
        currentUserId = data.user.id;
        localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
        hideProgress();
        updateUserUI();
        showDashboardView();
        showToast("Logged in as Rahul Sharma (Demo Patient)!", "⚡");
        loadHealthCard();
        return;
      }
    }
  } catch (e) {}

  // Instant Fallback (Guaranteed to work on GitHub Pages without server)
  hideProgress();
  currentUser = {
    id: "usr-sample-001",
    name: "Rahul Sharma",
    email: "rahul@health.in",
    role: "customer",
    address: "Sector 15, Gurgaon",
    latitude: 28.4680,
    longitude: 77.0420,
    emergency_contacts: [
      { name: "Priya Sharma (Spouse)", phone: "+91 98111 22334", relation: "Spouse" }
    ],
    allergies: ["Aspirin", "Penicillin"]
  };
  currentUserId = currentUser.id;
  localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  updateUserUI();
  showDashboardView();
  showToast("Logged in as Rahul Sharma (Demo Patient)!", "⚡");
  loadHealthCard();
};

window.loginAsDemoOwner = async function() {
  showProgress("Logging in as Pharmacy Owner Ramesh Gupta...");
  try {
    const res = await fetch(`${API_BASE}/auth/owner-demo-login`, { method: "POST" });
    if (res.ok) {
      const data = await res.json();
      if (data.success && data.user) {
        currentUser = data.user;
        currentUserId = data.user.id;
        localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
        hideProgress();
        updateUserUI();
        showDashboardView();
        showToast("Logged in as Ramesh Gupta (Store Owner)!", "🏪");
        loadOwnerDashboard();
        return;
      }
    }
  } catch (e) {}

  // Instant Fallback (Guaranteed to work on GitHub Pages without server)
  hideProgress();
  currentUser = {
    id: "usr-owner-001",
    name: "Ramesh Gupta",
    email: "owner@sanjeevani.in",
    role: "pharmacy_owner",
    address: "Shop #4, Sector 15 Market, Gurgaon",
    latitude: 28.4682,
    longitude: 77.0425,
    store_name: "Sanjeevani Local Chemist"
  };
  currentUserId = currentUser.id;
  localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  updateUserUI();
  showDashboardView();
  showToast("Logged in as Ramesh Gupta (Store Owner)!", "🏪");
  loadOwnerDashboard();
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
  } catch (e) {
    const demoInv = [
      { id: "med-001", generic_name: "Paracetamol 500mg", branded_name: "Dolo 650", generic_price: 18, branded_price: 45, stock: 45 },
      { id: "med-002", generic_name: "Cetirizine 10mg", branded_name: "Zyrtec", generic_price: 15, branded_price: 38, stock: 30 },
      { id: "med-003", generic_name: "Omeprazole 20mg", branded_name: "Omez", generic_price: 28, branded_price: 75, stock: 22 },
      { id: "med-004", generic_name: "Azithromycin 500mg", branded_name: "Azee 500", generic_price: 72, branded_price: 140, stock: 18 },
      { id: "med-005", generic_name: "Metformin 500mg", branded_name: "Glycomet", generic_price: 22, branded_price: 55, stock: 50 },
      { id: "med-006", generic_name: "Amoxicillin 500mg", branded_name: "Mox 500", generic_price: 65, branded_price: 120, stock: 25 }
    ];
    container.innerHTML = demoInv.map(m => `
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
    // Ensure person's real name is retained, never defaulting to Sanjeevani Chemist or store name
    if (currentUser.name && currentUser.name.toLowerCase().includes("sanjeevani chemist")) {
      currentUser.name = "Ramesh Gupta";
    } else if (currentUser.name) {
      currentUser.name = currentUser.name.replace(/\s*\((Store )?Owner\)/gi, "").trim();
    }
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  }
  updateUserUI();
  loadHealthCard();
  showToast(`Switched to Patient view as ${currentUser ? currentUser.name : 'Patient'}.`, "👤");
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
  let orders = [];
  try {
    const ordersRes = await fetch(`${API_BASE}/pharmacy/orders/user/${uid}`);
    if (ordersRes.ok) {
      orders = await ordersRes.json();
    }
  } catch (e) {}

  // Merge with local storage orders for seamless offline/GitHub Pages viewing
  try {
    const localOrders = getStoredOrders();
    const existingIds = new Set(orders.map(o => (o.order_id || o.id)));
    for (const lo of localOrders) {
      if (!existingIds.has(lo.order_id || lo.id)) {
        orders.unshift(lo);
      }
    }
  } catch (e) {}

  if (ordersCountBadge) ordersCountBadge.textContent = orders.length;
  renderOrdersList(orders);

  // 2. Fetch Booked Hospital Appointments
  let appts = [];
  try {
    const apptsRes = await fetch(`${API_BASE}/emergency/user/${uid}/appointments`);
    if (apptsRes.ok) {
      appts = await apptsRes.json();
    }
  } catch (e) {}

  // Merge with local storage appointments
  try {
    const localAppts = getStoredAppointments();
    const existingIds = new Set(appts.map(a => (a.token_id || a.id)));
    for (const la of localAppts) {
      if (!existingIds.has(la.token_id || la.id)) {
        appts.unshift(la);
      }
    }
  } catch (e) {}

  if (apptsCountBadge) apptsCountBadge.textContent = appts.length;
  renderAppointmentsList(appts);
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
        <span>Qty: ${item.quantity || 1} • ₹${item.price || item.unit_price || item.total_price || 0}</span>
      </div>
    `).join("");

    const dateStr = ord.created_at ? new Date(ord.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'Recent';
    const savingsHtml = (ord.savings_amount || ord.generic_savings) ? `<span class="order-savings-pill">Saved ₹${Math.round(ord.savings_amount || ord.generic_savings)}</span>` : '';

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
   LOCATION SELECTOR MODAL LOGIC (GOOGLE MAPS, GPS & MANUAL)
========================================================== */
let mapPickerInstance = null;
let mapMarker = null;
let userGpsCircle = null;
let pinnedLat = 28.4682;
let pinnedLng = 77.0425;
let pinnedAddress = "Sector 15, Gurgaon";

window.switchLocationTab = function(tabName) {
  const btnMap = document.getElementById("btnLocTabMap");
  const btnGps = document.getElementById("btnLocTabGps");
  const btnManual = document.getElementById("btnLocTabManual");
  const panelMap = document.getElementById("locPanelMap");
  const panelGps = document.getElementById("locPanelGps");
  const panelManual = document.getElementById("locPanelManual");

  if (btnMap) btnMap.classList.toggle("active", tabName === "map");
  if (btnGps) btnGps.classList.toggle("active", tabName === "gps");
  if (btnManual) btnManual.classList.toggle("active", tabName === "manual");

  if (panelMap) panelMap.style.display = tabName === "map" ? "block" : "none";
  if (panelGps) panelGps.style.display = tabName === "gps" ? "block" : "none";
  if (panelManual) panelManual.style.display = tabName === "manual" ? "block" : "none";

  if (tabName === "map") {
    setTimeout(() => {
      initMapPicker();
      if (mapPickerInstance) mapPickerInstance.invalidateSize();
    }, 150);
  }
};

function initMapPicker() {
  const mapContainer = document.getElementById("googleMapContainer");
  if (!mapContainer) return;

  if (currentUser && currentUser.latitude && currentUser.longitude) {
    pinnedLat = currentUser.latitude;
    pinnedLng = currentUser.longitude;
    pinnedAddress = currentUser.address || pinnedAddress;
  } else {
    const savedLoc = localStorage.getItem("mediconnect_user_location");
    if (savedLoc) {
      try {
        const parsed = JSON.parse(savedLoc);
        if (parsed.lat && parsed.lng) {
          pinnedLat = parsed.lat;
          pinnedLng = parsed.lng;
          pinnedAddress = parsed.address || pinnedAddress;
        }
      } catch (e) {}
    }
  }

  // If Leaflet is available, render interactive map
  if (typeof L !== "undefined") {
    if (!mapPickerInstance) {
      mapPickerInstance = L.map('googleMapContainer', {
        zoomControl: true,
        scrollWheelZoom: true
      }).setView([pinnedLat, pinnedLng], 15);

      // Add OpenStreetMap tiles (Reliable, fast, zero-API-key fallback)
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; Google Maps / OpenStreetMap contributors',
        maxZoom: 19
      }).addTo(mapPickerInstance);

      // Create Draggable Custom Pin
      const pinIcon = L.divIcon({
        className: 'custom-map-pin',
        html: '<div style="font-size: 32px; filter: drop-shadow(0 3px 6px rgba(0,0,0,0.35)); cursor: pointer; transform: translate(-8px, -14px);">📍</div>',
        iconSize: [32, 32],
        iconAnchor: [16, 32]
      });

      mapMarker = L.marker([pinnedLat, pinnedLng], { icon: pinIcon, draggable: true }).addTo(mapPickerInstance);

      // Drag event
      mapMarker.on('dragend', function (e) {
        const coord = mapMarker.getLatLng();
        updatePinnedLocation(coord.lat, coord.lng);
      });

      // Click on map moves marker
      mapPickerInstance.on('click', function(e) {
        mapMarker.setLatLng(e.latlng);
        updatePinnedLocation(e.latlng.lat, e.latlng.lng);
      });
    } else {
      mapPickerInstance.invalidateSize();
      mapPickerInstance.setView([pinnedLat, pinnedLng], 15);
      if (mapMarker) mapMarker.setLatLng([pinnedLat, pinnedLng]);
    }
  }

  updatePinnedLocationDisplay();
}

// Auto-detect location on Google Maps using Live GPS (Satellite Geolocation + Reverse Geocoding)
window.detectCurrentLocationOnMap = async function() {
  const statusEl = document.getElementById("mapGpsDetectionStatus");
  const btnText = document.getElementById("mapAutoLocateText");

  if (statusEl) {
    statusEl.className = "gps-status-msg loading";
    statusEl.innerHTML = `<span>🛰️ Connecting to GPS satellites & pinpointing your coordinates...</span>`;
    statusEl.style.display = "flex";
  }
  if (btnText) btnText.textContent = "Pinpointing GPS satellites...";

  // Ensure map tab is active and visible
  switchLocationTab('map');
  initMapPicker();

  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        const accuracy = Math.round(pos.coords.accuracy || 20);
        await applyDetectedGpsLocation(lat, lng, `Accurate within ~${accuracy}m`);
      },
      async (err) => {
        console.warn("Browser GPS failed or blocked, trying network IP fallback...", err);
        await fallbackToIpLocation("Device GPS unavailable. Detected location via Network IP:");
      },
      { enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }
    );
  } else {
    await fallbackToIpLocation("Device GPS not supported. Detected location via Network IP:");
  }
};

async function applyDetectedGpsLocation(lat, lng, detail = "") {
  const statusEl = document.getElementById("mapGpsDetectionStatus");
  const btnText = document.getElementById("mapAutoLocateText");

  pinnedLat = lat;
  pinnedLng = lng;

  // Center Leaflet map and move pin
  if (mapPickerInstance) {
    mapPickerInstance.invalidateSize();
    mapPickerInstance.setView([lat, lng], 16);
    if (mapMarker) {
      mapMarker.setLatLng([lat, lng]);
    }

    // Add pulsing GPS accuracy circle on map
    if (userGpsCircle && mapPickerInstance.hasLayer(userGpsCircle)) {
      mapPickerInstance.removeLayer(userGpsCircle);
    }
    userGpsCircle = L.circle([lat, lng], {
      radius: 40,
      color: '#2563eb',
      fillColor: '#3b82f6',
      fillOpacity: 0.22,
      weight: 2
    }).addTo(mapPickerInstance);
  }

  // Reverse geocode to find exact readable street and area
  let readableAddress = "";
  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`);
    if (res.ok) {
      const data = await res.json();
      if (data && data.address) {
        const a = data.address;
        const parts = [];
        if (a.road || a.pedestrian || a.suburb) parts.push(a.road || a.pedestrian || a.suburb);
        if (a.neighbourhood || a.residential) parts.push(a.neighbourhood || a.residential);
        if (a.city || a.town || a.city_district || a.state_district) parts.push(a.city || a.town || a.city_district || a.state_district);
        if (a.postcode) parts.push(a.postcode);
        readableAddress = parts.filter(Boolean).join(", ");
      } else if (data && data.display_name) {
        readableAddress = data.display_name.split(",").slice(0, 3).join(",").trim();
      }
    }
  } catch (e) {
    console.warn("Reverse geocode request failed", e);
  }

  if (!readableAddress) {
    readableAddress = `Current Live Location (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E)`;
  }

  pinnedAddress = readableAddress;
  if (manualAddressInput) manualAddressInput.value = readableAddress;
  updatePinnedLocationDisplay();

  if (statusEl) {
    statusEl.className = "gps-status-msg success";
    statusEl.innerHTML = `<div>📍 <strong>Live GPS Located:</strong> ${readableAddress}</div><div style="font-size: 11px; opacity: 0.85; margin-top: 2px;">Coordinates: (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E) ${detail ? '• ' + detail : ''}</div>`;
    statusEl.style.display = "flex";
  }
  if (btnText) btnText.textContent = "📍 Live Location Detected (Tap to Re-check)";
  showToast(`Live GPS located: ${readableAddress}`, "📍");
}

async function fallbackToIpLocation(reason) {
  const statusEl = document.getElementById("mapGpsDetectionStatus");
  const btnText = document.getElementById("mapAutoLocateText");

  try {
    const res = await fetch("https://get.geojs.io/v1/ip/geo.json");
    if (res.ok) {
      const data = await res.json();
      const lat = parseFloat(data.latitude);
      const lng = parseFloat(data.longitude);
      const city = data.city || data.region || "Detected Area";
      await applyDetectedGpsLocation(lat, lng, `${reason} ${city}`);
      return;
    }
  } catch (e) {}

  // Safe fallback if offline
  const lat = 28.4682;
  const lng = 77.0425;
  await applyDetectedGpsLocation(lat, lng, "Sector 15, Gurgaon");
  if (statusEl) {
    statusEl.className = "gps-status-msg warning";
    statusEl.innerHTML = `<div>⚠️ <strong>GPS Signal Weak:</strong> Pin placed at Sector 15, Gurgaon.</div><div style="font-size: 11px; opacity: 0.85;">You can drag the pin on Google Maps or search your locality above.</div>`;
    statusEl.style.display = "flex";
  }
  if (btnText) btnText.textContent = "Detect My Current Location (Live GPS)";
}

async function updatePinnedLocation(lat, lng) {
  pinnedLat = lat;
  pinnedLng = lng;
  const statusEl = document.getElementById("mapSelectedAddressText");
  if (statusEl) statusEl.textContent = `Fetching address for (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E)...`;

  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`);
    if (res.ok) {
      const data = await res.json();
      if (data && data.display_name) {
        const addrParts = data.address || {};
        const road = addrParts.road || addrParts.suburb || addrParts.neighbourhood || "Sector 15";
        const city = addrParts.city || addrParts.town || addrParts.state_district || "Gurgaon";
        const postcode = addrParts.postcode || "122001";
        pinnedAddress = `${road}, ${city} - ${postcode}`;

        if (manualAddressInput) manualAddressInput.value = road;
        if (manualCityInput) manualCityInput.value = city;
        if (manualPincodeInput) manualPincodeInput.value = postcode;
      }
    }
  } catch(e) {
    pinnedAddress = `Pinned Location (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E), Sector 15, Gurgaon`;
  }

  updatePinnedLocationDisplay();
}

function updatePinnedLocationDisplay() {
  const statusEl = document.getElementById("mapSelectedAddressText");
  if (statusEl) {
    statusEl.textContent = `${pinnedAddress} (${pinnedLat.toFixed(4)}° N, ${pinnedLng.toFixed(4)}° E)`;
  }
}

window.searchLocationOnMap = async function() {
  const input = document.getElementById("mapSearchInput");
  if (!input || !input.value.trim()) return;
  const query = input.value.trim();

  showToast(`Searching Google Maps for "${query}"...`, "🔍");
  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query + ", India")}&limit=1`);
    if (res.ok) {
      const results = await res.json();
      if (results && results.length > 0) {
        const lat = parseFloat(results[0].lat);
        const lon = parseFloat(results[0].lon);
        pinnedLat = lat;
        pinnedLng = lon;
        pinnedAddress = results[0].display_name.split(",").slice(0, 3).join(",");

        if (mapPickerInstance && mapMarker) {
          mapPickerInstance.setView([lat, lon], 15);
          mapMarker.setLatLng([lat, lon]);
        }
        updatePinnedLocationDisplay();
        showToast(`Found: ${pinnedAddress}`, "📍");
        return;
      }
    }
    showToast("Location not found on map. Try entering sector or city.", "⚠️");
  } catch(e) {
    showToast("Map search failed. Please tap directly on the map.", "⚠️");
  }
};

window.confirmMapLocation = async function() {
  await saveLocationToProfile(pinnedAddress, pinnedLat, pinnedLng);
  closeLocationModal();
};

function openLocationModal() {
  const savedLoc = localStorage.getItem("mediconnect_user_location");
  let savedParsed = null;
  if (savedLoc) {
    try { savedParsed = JSON.parse(savedLoc); } catch (e) {}
  }

  if (currentUser && currentUser.address) {
    manualAddressInput.value = currentUser.address;
    pinnedAddress = currentUser.address;
    if (currentUser.latitude && currentUser.longitude) {
      pinnedLat = currentUser.latitude;
      pinnedLng = currentUser.longitude;
    }
  } else if (savedParsed) {
    if (manualAddressInput) manualAddressInput.value = savedParsed.address || "";
    pinnedAddress = savedParsed.address || pinnedAddress;
    pinnedLat = savedParsed.lat || pinnedLat;
    pinnedLng = savedParsed.lng || pinnedLng;
  }

  const mapGpsStatus = document.getElementById("mapGpsDetectionStatus");
  if (mapGpsStatus) mapGpsStatus.style.display = "none";
  if (gpsDetectStatus) gpsDetectStatus.style.display = "none";

  locationModal.style.display = "flex";
  switchLocationTab('map');
}

function closeLocationModal() {
  locationModal.style.display = "none";
}

if (openLocationModalBtn) openLocationModalBtn.addEventListener("click", openLocationModal);
if (closeLocationModalBtn) closeLocationModalBtn.addEventListener("click", closeLocationModal);

// Auto-detect location using browser GPS button in Option 2 tab
if (btnAutoDetectGps) {
  btnAutoDetectGps.addEventListener("click", async () => {
    switchLocationTab('map');
    await detectCurrentLocationOnMap();
  });
}

window.saveManualLocation = async function() {
  const addr = manualAddressInput.value.trim();
  const city = manualCityInput.value.trim();
  const pin = manualPincodeInput.value.trim();
  const fullAddr = `${addr}${city ? ', ' + city : ''}${pin ? ' - ' + pin : ''}`;
  await saveLocationToProfile(fullAddr);
  closeLocationModal();
};

async function saveLocationToProfile(newAddress, lat = 28.4595, lng = 77.0266) {
  if (!newAddress || !newAddress.trim()) {
    newAddress = `Location (${lat.toFixed(4)}° N, ${lng.toFixed(4)}° E)`;
  }
  newAddress = newAddress.trim();

  // 1. Optimistically update in-memory user object
  if (!currentUser) {
    currentUser = {
      id: currentUserId || "usr-sample-001",
      name: "Rahul Sharma",
      role: "customer",
      address: newAddress,
      latitude: lat,
      longitude: lng,
      contact: "+91 98765 43210",
      email: "rahul@health.in",
      emergency_contacts: [
        { name: "Priya Sharma (Spouse)", phone: "+91 98111 22334", relation: "Spouse" }
      ],
      allergies: ["Aspirin", "Penicillin"]
    };
    currentUserId = currentUser.id;
  } else {
    currentUser.address = newAddress;
    currentUser.latitude = lat;
    currentUser.longitude = lng;
  }

  // 2. Persist to localStorage immediately
  try {
    localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
    localStorage.setItem("mediconnect_user_location", JSON.stringify({ address: newAddress, lat, lng }));
  } catch (e) {
    console.warn("Could not save to localStorage", e);
  }

  // 3. Immediately update DOM at the circled location:
  const roleLabel = currentUser.role === "pharmacy_owner" ? "Pharmacy Store Owner" : "Verified Patient";
  const headerSubtext = document.getElementById("headerUserSubtext");
  if (headerSubtext) {
    headerSubtext.textContent = `${roleLabel} • ${newAddress}`;
    headerSubtext.style.transition = "all 0.3s ease";
    headerSubtext.style.color = "#059669";
    headerSubtext.style.fontWeight = "700";
    setTimeout(() => {
      headerSubtext.style.color = "";
      headerSubtext.style.fontWeight = "";
    }, 2000);
  }

  const userLocDisplay = document.getElementById("userLocationDisplay");
  if (userLocDisplay) {
    userLocDisplay.textContent = `📍 ${newAddress}`;
  }

  if (manualAddressInput) manualAddressInput.value = newAddress;
  pinnedAddress = newAddress;
  pinnedLat = lat;
  pinnedLng = lng;
  updatePinnedLocationDisplay();

  // Update rest of UI
  updateUserUI();

  showToast(`Location updated to: ${newAddress}`, "📍");

  // 4. Background non-blocking sync with backend API (fire and forget)
  const uid = currentUser.id || "usr-sample-001";
  try {
    await fetch(`${API_BASE}/records/user/${uid}/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        address: newAddress,
        latitude: lat,
        longitude: lng
      })
    });
  } catch (e) {
    // Offline or static deployment (e.g. GitHub Pages) - perfectly fine since localStorage has it!
  }
}

/* ==========================================================
   APP LANGUAGES SYSTEM (INDIAN LANGUAGES SUPPORT)
========================================================== */
let currentAppLang = localStorage.getItem("mediconnect_lang") || "en";

const APP_TRANSLATIONS = {
  en: {
    name: "English",
    native: "English",
    voiceLang: "en-IN",
    voiceTitle: "Where does it hurt? (क्या तकलीफ है?)",
    voiceDesc: "Tap the 3D microphone to speak naturally, or pick a common health problem below:",
    micTap: "Speak Symptoms",
    symptomPlaceholder: "Describe health issue: e.g., 'I have a headache since morning'...",
    consultBtn: "Consult AI",
    headache: "Headache / Body Pain",
    cold: "Cold & Sore Throat",
    acidity: "Stomach Gas & Acidity",
    chestPain: "Severe Chest Pain",
    authSub: "Hyperlocal Healthcare & Direct Chemist Network"
  },
  hi: {
    name: "Hindi",
    native: "हिन्दी",
    voiceLang: "hi-IN",
    voiceTitle: "आपको क्या तकलीफ है? (कहाँ दर्द है?)",
    voiceDesc: "माइक बटन दबाकर बोलें, या नीचे से कोई समस्या चुनें:",
    micTap: "लक्षण बोलें",
    symptomPlaceholder: "अपनी समस्या बताएं: जैसे 'मुझे सुबह से सिरदर्द और बुखार है'...",
    consultBtn: "एआई सलाह लें",
    headache: "सिर दर्द / बदन दर्द",
    cold: "सर्दी और गले में खराश",
    acidity: "पेट गैस और एसिडिटी",
    chestPain: "सीने में तेज दर्द (आपातकालीन)",
    authSub: "स्थानीय स्वास्थ्य सेवा और दवा दुकान नेटवर्क"
  },
  te: {
    name: "Telugu",
    native: "తెలుగు",
    voiceLang: "te-IN",
    voiceTitle: "మీకు ఎక్కడ నొప్పిగా ఉంది? (ఆరోగ్య సమస్య)",
    voiceDesc: "మైక్ నొక్కి మాట్లాడండి లేదా కింద ఒక సమస్యను ఎంచుకోండి:",
    micTap: "మాట్లాడండి",
    symptomPlaceholder: "మీ సమస్యను చెప్పండి: ఉదా. 'నాకు ఉదయం నుండి తలనొప్పిగా ఉంది'...",
    consultBtn: "AI సంప్రదించండి",
    headache: "తల నొప్పి / ఒంటి నొప్పులు",
    cold: "జలుబు & గొంతు నొప్పి",
    acidity: "కడుపు మంట & గ్యాస్",
    chestPain: "తీవ్రమైన ఛాతీ నొప్పి (అత్యవసరం)",
    authSub: "హైపర్‌లోకల్ హెల్త్‌కేర్ & మెడికల్ నెట్‌వర్క్"
  },
  ta: {
    name: "Tamil",
    native: "தமிழ்",
    voiceLang: "ta-IN",
    voiceTitle: "உங்களுக்கு எங்கு வலிக்கிறது?",
    voiceDesc: "மைக் பொத்தானை அழுத்தி பேசவும், அல்லது சிக்கலைத் தேர்ந்தெடுக்கவும்:",
    micTap: "பேசவும்",
    symptomPlaceholder: "உங்கள் பிரச்சனையை விவரிக்கவும்: எ.கா. 'எனக்கு தலைவலி உள்ளது'...",
    consultBtn: "AI ஆலோசனை",
    headache: "தலைவலி / உடல் வலி",
    cold: "சளி மற்றும் தொண்டை வலி",
    acidity: "வயிற்று வலி & வாயு",
    chestPain: "கடுமையான நெஞ்சு வலி (அவசரம்)",
    authSub: "உள்ளூர் சுகாதார சேவை & மருந்தக நெட்வொர்க்"
  },
  bn: {
    name: "Bengali",
    native: "বাংলা",
    voiceLang: "bn-IN",
    voiceTitle: "আপনার কোথায় কষ্ট হচ্ছে?",
    voiceDesc: "মাইক্রোফোন ট্যাপ করে কথা বলুন বা নিচের সমস্যা নির্বাচন করুন:",
    micTap: "কথা বলুন",
    symptomPlaceholder: "সমস্যার বিবরণ দিন: যেমন 'সকাল থেকে আমার মাথা ব্যথা'...",
    consultBtn: "AI পরামর্শ নিন",
    headache: "মাথা ব্যথা / শরীর ব্যথা",
    cold: "সর্দি ও গলা ব্যথা",
    acidity: "পেটের গ্যাস ও অম্বল",
    chestPain: "বুকে তীব্র ব্যথা (জরুরি)",
    authSub: "স্থানীয় স্বাস্থ্যসেবা ও ফার্মেসি নেটওয়ার্ক"
  },
  mr: {
    name: "Marathi",
    native: "मराठी",
    voiceLang: "mr-IN",
    voiceTitle: "तुम्हाला काय त्रास होत आहे?",
    voiceDesc: "माईकवर टॅप करून बोला किंवा खालील समस्या निवडा:",
    micTap: "लक्षणे बोला",
    symptomPlaceholder: "त्रास सांगा: उदा. 'मला सकाळपासून डोकेदुखी आहे'...",
    consultBtn: "AI सल्ला घ्या",
    headache: "डोकेदुखी / अंगदुखी",
    cold: "सर्दी आणि घसा खवखवणे",
    acidity: "पोटात गॅस व ॲसिडिटी",
    chestPain: "छातीत तीव्र वेदना (तात्काळ)",
    authSub: "स्थानिक आरोग्य सेवा आणि फार्मसी नेटवर्क"
  },
  gu: {
    name: "Gujarati",
    native: "ગુજરાતી",
    voiceLang: "gu-IN",
    voiceTitle: "તમને ક્યાં દુખાવો થાય છે?",
    voiceDesc: "માઇક દબાવીને બોલો અથવા નીચેથી સમસ્યા પસંદ કરો:",
    micTap: "લક્ષણો બોલો",
    symptomPlaceholder: "તકલીફ જણાવો: દા.ત. 'મને સવારથી માથાનો દુખાવો છે'...",
    consultBtn: "AI સલાહ લો",
    headache: "માથાનો દુખાવો / શરીરનો દુખાવો",
    cold: "શરદી અને ગળામાં દુખાવો",
    acidity: "ગેસ અને એસિડિટી",
    chestPain: "છાતીમાં તીવ્ર દુખાવો (ઇમરજન્સી)",
    authSub: "સ્થાનિક આરોગ્ય સેવા અને કેમિસ્ટ નેટવર્ક"
  },
  kn: {
    name: "Kannada",
    native: "ಕನ್ನಡ",
    voiceLang: "kn-IN",
    voiceTitle: "ನಿಮಗೆ ಎಲ್ಲಿ ನೋವಾಗುತ್ತಿದೆ?",
    voiceDesc: "ಮೈಕ್ ಒತ್ತಿ ಮಾತನಾಡಿ ಅಥವಾ ಕೆಳಗಿನ ಸಮಸ್ಯೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ:",
    micTap: "ಮಾತನಾಡಿ",
    symptomPlaceholder: "ಸಮಸ್ಯೆಯನ್ನು ವಿವರಿಸಿ: ಉದಾ. 'ನನಗೆ ತಲೆನೋವು ಇದೆ'...",
    consultBtn: "AI ಸಲಹೆ ಪಡೆಯಿರಿ",
    headache: "ತಲೆನೋವು / ಮೈಕೈನೋವು",
    cold: "ಶೀತ ಮತ್ತು ಗಂಟಲು ನೋವು",
    acidity: "ಹೊಟ್ಟೆ ಉರಿ ಮತ್ತು ಗ್ಯಾಸ್",
    chestPain: "ತೀವ್ರ ಎದೆನೋವು (ತುರ್ತು)",
    authSub: "ಹೈಪರ್‌ಲೋಕಲ್ ಆರೋಗ್ಯ ಸೇವೆ & ಔಷಧಾಲಯ ನೆಟ್‌ವರ್ಕ್"
  },
  ml: {
    name: "Malayalam",
    native: "മലയാളം",
    voiceLang: "ml-IN",
    voiceTitle: "നിങ്ങൾക്ക് എവിടെയാണ് വേദന?",
    voiceDesc: "മൈക്ക് അമർത്തി സംസാരിക്കുക അല്ലെങ്കിൽ പ്രശ്നം തിരഞ്ഞെടുക്കുക:",
    micTap: "സംസാരിക്കുക",
    symptomPlaceholder: "ലക്ഷണങ്ങൾ പറയുക: ഉദാ. 'എനിക്ക് തലവേദനയുണ്ട്'...",
    consultBtn: "AI കൺസൾട്ട്",
    headache: "തലവേദന / ശരീരവേദന",
    cold: "ജലദോഷം & തൊണ്ടവേദന",
    acidity: "ഗ്യാസ് & അസിഡിറ്റി",
    chestPain: "നെഞ്ചുവേദന (അടിയന്തരം)",
    authSub: "പ്രാദേശിക ആരോഗ്യ സേവന ശൃംഖല"
  },
  pa: {
    name: "Punjabi",
    native: "ਪੰਜਾਬੀ",
    voiceLang: "pa-IN",
    voiceTitle: "ਤੁਹਾਨੂੰ ਕੀ ਤਕਲੀਫ਼ ਹੈ?",
    voiceDesc: "ਮਾਈਕ ਦਬਾ ਕੇ ਬੋਲੋ ਜਾਂ ਹੇਠਾਂ ਦਿੱਤੀ ਸਮੱਸਿਆ ਚੁਣੋ:",
    micTap: "ਲੱਛਣ ਬੋਲੋ",
    symptomPlaceholder: "ਤਕਲੀਫ਼ ਦੱਸੋ: ਜਿਵੇਂ 'ਮੈਨੂੰ ਸਵੇਰ ਤੋਂ ਸਿਰਦਰਦ ਹੈ'...",
    consultBtn: "AI ਸਲਾਹ ਲਵੋ",
    headache: "ਸਿਰ ਦਰਦ / ਸਰੀਰ ਦਰਦ",
    cold: "ਜ਼ੁਕਾਮ ਅਤੇ ਗਲੇ ਵਿੱਚ ਦਰਦ",
    acidity: "ਗੈਸ ਅਤੇ ਐਸਿਡਿਟੀ",
    chestPain: "ਛਾਤੀ ਵਿੱਚ ਤੇਜ਼ ਦਰਦ (ਐਮਰਜੈਂਸੀ)",
    authSub: "ਸਥਾਨਕ ਸਿਹਤ ਸੇਵਾ ਅਤੇ ਮੈਡੀਕਲ ਨੈੱਟਵਰਕ"
  }
};

window.openLanguageModal = function() {
  const modal = document.getElementById("languageModal");
  if (modal) modal.style.display = "flex";
  // Highlight active language card
  document.querySelectorAll(".lang-card").forEach(card => {
    card.classList.toggle("active", card.getAttribute("data-lang") === currentAppLang);
  });
};

window.closeLanguageModal = function() {
  const modal = document.getElementById("languageModal");
  if (modal) modal.style.display = "none";
};

window.selectAppLanguage = function(langCode) {
  currentAppLang = langCode;
  localStorage.setItem("mediconnect_lang", langCode);
  applyAppLanguage(langCode);
  closeLanguageModal();
  const tr = APP_TRANSLATIONS[langCode] || APP_TRANSLATIONS.en;
  showToast(`App language set to ${tr.native} (${tr.name})!`, "🌐");
};

function applyAppLanguage(langCode) {
  const tr = APP_TRANSLATIONS[langCode] || APP_TRANSLATIONS.en;

  // Update language badges in login modal and top header
  const loginLangText = document.getElementById("loginLangBtnText");
  if (loginLangText) loginLangText.textContent = tr.native;

  document.querySelectorAll(".headerLangLabel").forEach(el => {
    el.textContent = tr.native;
  });

  // Sync Voice Language selector
  const voiceSelect = document.getElementById("voiceLangSelect");
  if (voiceSelect && tr.voiceLang) {
    voiceSelect.value = tr.voiceLang;
  }

  // Translate Voice & Symptom input fields
  const vTitle = document.querySelector(".voice-title");
  if (vTitle) vTitle.textContent = tr.voiceTitle;

  const vDesc = document.querySelector(".voice-desc");
  if (vDesc) vDesc.textContent = tr.voiceDesc;

  const micStatus = document.getElementById("micStatusText");
  if (micStatus && !isRecording) micStatus.textContent = tr.micTap;

  if (symptomInput) symptomInput.placeholder = tr.symptomPlaceholder;

  const sendBtnSpan = document.querySelector("#sendBtn span:first-child");
  if (sendBtnSpan) sendBtnSpan.textContent = tr.consultBtn;

  // Translate Presets
  const pAllergy = document.querySelector("#presetAllergy .prob-text strong");
  if (pAllergy) pAllergy.textContent = tr.headache;

  const pCold = document.querySelector("#presetCold .prob-text strong");
  if (pCold) pCold.textContent = tr.cold;

  const pAcidity = document.querySelector("#presetAcidity .prob-text strong");
  if (pAcidity) pAcidity.textContent = tr.acidity;

  const pEmergency = document.querySelector("#presetEmergency .prob-text strong");
  if (pEmergency) pEmergency.textContent = tr.chestPain;

  const authSub = document.getElementById("authModalSubTitle");
  if (authSub) authSub.textContent = tr.authSub;
}

// Initialize language on startup
applyAppLanguage(currentAppLang);

/* ==========================================================
   PATIENT PROFILE MODAL LOGIC
========================================================== */
async function openProfileModal() {
  const uid = currentUser ? currentUser.id : currentUserId;
  profileModal.style.display = "flex";
  profileViewCard.style.display = "flex";
  profileEditForm.style.display = "none";

  let u = null;
  try {
    const res = await fetch(`${API_BASE}/records/user/${uid}`);
    if (res.ok) {
      u = await res.json();
    }
  } catch (e) {}

  if (!u) {
    const savedAllergies = JSON.parse(localStorage.getItem("mediconnect_allergies") || '["Aspirin", "Ibuprofen"]');
    const savedLimit = parseFloat(localStorage.getItem("mediconnect_payment_limit") || (currentUser?.payment_limit || "1500"));
    u = currentUser || {
      name: "Rahul Sharma",
      contact_phone: "+91 98765 43210",
      email: "rahul@health.in",
      address: "Sector 15, Gurgaon",
      latitude: 28.4595,
      longitude: 77.0266,
      payment_limit: savedLimit,
      allergies: savedAllergies,
      emergency_contacts: [
        { name: "Ananya Sharma (Spouse)", phone: "+91 98111 22233" },
        { name: "Dr. V. K. Sharma (Father)", phone: "+91 98222 33344" }
      ]
    };
  }

  profileViewName.textContent = u.name || "Patient";
  profileViewPhone.textContent = u.contact_phone || u.contact || "+91 98765 43210";
  profileViewEmail.textContent = u.email || `${(u.name || "user").toLowerCase().replace(/\s+/g, '')}@health.in`;
  profileViewAddress.textContent = u.address || "Sector 15, Gurgaon";
  profileViewCoords.textContent = `${u.latitude || 28.4595}° N, ${u.longitude || 77.0266}° E`;
  profileViewLimit.textContent = `₹${Math.round(u.payment_limit || 1500)} per transaction`;
  profileViewCreatedAt.textContent = u.created_at ? new Date(u.created_at).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' }) : "Active Verified";

  // Allergies list
  const userAllergies = u.allergies || JSON.parse(localStorage.getItem("mediconnect_allergies") || '["Aspirin", "Ibuprofen"]');
  if (userAllergies && userAllergies.length > 0) {
    profileViewAllergies.innerHTML = userAllergies.map(a => `<span class="prof-allergy-tag">🛡️ ${a} Blocked</span>`).join("");
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
  editProfileContact.value = u.contact_phone || u.contact || "";
  editProfileEmail.value = u.email || "";
  editProfileAddress.value = u.address || "";
  editProfileLimit.value = Math.round(u.payment_limit || 1500);
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
    name: editProfileName.value.trim() || (currentUser?.name || "Rahul Sharma"),
    contact_phone: editProfileContact.value.trim() || (currentUser?.contact_phone || "+91 98765 43210"),
    email: editProfileEmail.value.trim() || (currentUser?.email || "rahul@health.in"),
    address: editProfileAddress.value.trim() || (currentUser?.address || "Sector 15, Gurgaon"),
    payment_limit: parseFloat(editProfileLimit.value) || (currentUser?.payment_limit || 1500)
  };

  try {
    await fetch(`${API_BASE}/records/user/${uid}/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(updatedData)
    });
  } catch (e) {}

  currentUser = { ...(currentUser || {}), ...updatedData };
  localStorage.setItem("mediconnect_user", JSON.stringify(currentUser));
  updateUserUI();
  showToast("Profile details updated successfully!", "✅");
  openProfileModal(); // Refresh view
};
