# Privacy Policy

**Vachika Lekhini — Srinishtha Technologies Pvt. Ltd.**

Effective: 22 June 2026 · Version 1.0

---

## 1. Who We Are

**Srinishtha Technologies Pvt. Ltd.** ("we", "our", "us") is the Data Fiduciary of the Vachika Lekhini app, incorporated under the Companies Act, 2013. This policy is issued in compliance with the **Digital Personal Data Protection Act, 2023 (DPDP Act)**.

---

## 2. Scope & Your Consent

This policy applies to all users ("Data Principal") of the Vachika Lekhini app on Android or iOS.

By registering an account, you give **free, specific, informed, and unambiguous consent** for us to process your personal data as described here. You may withdraw consent at any time by deleting your account.

---

## 3. Data We Collect

### Account & Identity

| Data | Purpose | Where Stored |
|------|---------|-------------|
| Mobile phone number | Account creation, OTP, password reset | Server |
| Password (hashed) | Authentication | Server (hashed) |
| OTP codes (transient) | Identity verification | Not stored |
| JWT tokens | Authenticated access | Device secure storage |
| Referral code (optional) | Community referrals | Server |

### Profile

| Data | Purpose | Where Stored |
|------|---------|-------------|
| Full name | Personalisation, leaderboard | Server + local cache |
| Gender | Profile completeness | Server |
| Birth year | Age verification | Server |
| Mother tongue / preferred language | Script & language preference | Server |
| Location / city (optional) | Regional personalisation | Server |
| Profile photo (JPG) | Avatar display | Device only |

### Address (optional)

| Data | Where Stored |
|------|-------------|
| Address lines 1 & 2 | Server |
| City, State | Server |
| PIN code | Server |
| Address type (Home / Work / Other) | Server |

### Biometric & Behavioural Data

> **Your voice recordings and handwriting images are processed entirely on your device. They are never transmitted to our servers.**

| Data | Purpose | Where Stored |
|------|---------|-------------|
| Voice chant samples (audio) | Offline speech recognition to count repetitions | Device only |
| Voice enrolment metadata | Recognition training state | Device only |
| Handwriting images (PNG, max 10) | Offline OCR to verify written mantras | Device only |
| Handwriting metadata (mode, mantra, timestamp) | Sample management | Device only |

### Practice & Activity

| Data | Purpose | Where Stored |
|------|---------|-------------|
| Practice session records | Progress, streaks, stats | Local SQLite + Server |
| Program / goal data | Goal management | Local SQLite + Server |
| Reward event log | Incentive system | Local SQLite + Server |
| Leaderboard position (aggregated, public) | Community ranking | Server |

### Device & Technical

| Data | Purpose | Where Stored |
|------|---------|-------------|
| Device ID (stable UUID, generated at install) | Device registration | Device + Server |
| Platform (android / ios) & app version | Compatibility, support | Server |
| UI & notification preferences | Personalisation | Device only |

---

## 4. Why We Process Your Data

We process your data based on **your consent** (DPDP Act §6) and **legitimate use** for service delivery (§7).

| Purpose | Legal Basis |
|---------|-------------|
| Account creation & authentication | Consent (contractual necessity) |
| Profile personalisation | Consent |
| Address management | Consent |
| Voice mantra counting (on-device only) | Explicit consent — biometric data |
| Handwriting OCR (on-device only) | Explicit consent |
| Practice tracking | Consent / Legitimate use |
| Rewards programme | Legitimate use (contracted benefit) |
| Community features & leaderboard | Consent |
| Social share / invite (user-initiated) | Consent |
| Device management & notifications | Legitimate use |
| Security & fraud prevention | Legitimate use |
| Compliance with law | Legal obligation (§7(f)) |

---

## 5. On-Device Processing — No Data Leaves Your Phone

| Feature | Technology | What stays on device |
|---------|------------|---------------------|
| Voice recognition | Vosk ASR (offline, bundled model) | All audio — only sample count & timestamp synced |
| Handwriting OCR | Tesseract (offline, bundled traineddata) | All images — none transmitted |
| Avatar generation | Deterministic gradient from seed | All image data — only integer seed synced |

---

## 6. Who We Share Data With

We **do not sell, rent, or trade** your personal data. We use no third-party analytics, advertising networks, or crash-reporting services.

| Recipient | Data Shared | Reason |
|-----------|-------------|--------|
| Our backend API (Srinishtha servers) | Account, profile, address, session, reward, device data | Core service delivery |
| SMS gateway | Phone number + OTP message only | Account verification |
| Public leaderboard | Display name, aggregate chant count only | Community feature (opt-in) |
| Government / law enforcement | As compelled by valid legal order | Legal obligation |

**No Firebase. No Google Analytics. No advertising platforms.**

Social share actions (WhatsApp, Instagram, etc.) are user-initiated and governed by those platforms' own policies.

---

## 7. How Long We Keep Your Data

| Data | Retention |
|------|-----------|
| Active account data | Retained while account is active |
| After account deletion | All server data deleted within **30 days** |
| JWT tokens | Revoked immediately on logout or deletion |
| Voice samples | Device only; deleted when you clear enrolment or uninstall |
| Handwriting images | Device only; deleted with enrolment reset or uninstall |
| Server backups | Purged within **90 days** after account deletion |
| Legal hold | Retained only for the duration required by law |

---

## 8. Your Rights Under the DPDP Act 2023

**Right to Information (§11)**
Know what personal data we hold and how it is processed.

**Right to Correction (§12)**
Correct inaccurate data via Settings → Edit Profile.

**Right to Erasure (§12)**
Delete your account and all data via Settings → Delete Account.

**Right to Withdraw Consent (§6)**
Withdraw consent at any time; this may limit certain features.

**Right to Grievance Redressal (§13)**
File a complaint with our Grievance Officer; we respond within 30 days.

**Right to Nominate (§14)**
Nominate someone to exercise your rights in case of death or incapacity.

To exercise any right, email **privacy@srinishtha.com** or use the in-app support. Unresolved complaints may be escalated to the **Data Protection Board of India**.

---

## 9. Children's Privacy

The App is not directed at children below **18 years**. Birth year is collected at sign-up to screen for underage users. If we discover a user is under 18, we will delete their account promptly.

Parents or guardians may contact **privacy@srinishtha.com** if they believe a minor has registered.

---

## 10. Security Measures

| Layer | Measure |
|-------|---------|
| Transport | TLS 1.2+ for all API communication |
| Token storage | iOS Keychain / Android EncryptedSharedPreferences |
| Local database | Drift SQLite with app-level access control; Hive CE encrypted boxes |
| Authentication | OTP verification + server-side hashed passwords |
| Biometric data | Never transmitted; processed only by offline on-device models |
| API access control | All endpoints require valid JWT |

In the event of a data breach, we will notify you and the Data Protection Board of India within prescribed timelines.

---

## 11. Cross-Border Data Transfers

Our servers are located in India. Where any processing occurs outside India, we ensure compliance with DPDP Act provisions and applicable government notifications.

---

## 12. Changes to This Policy

We may update this policy from time to time. We will notify you of material changes via an in-app notification and seek fresh consent where required. Continued use after a notified update constitutes acceptance.

---

## 13. Grievance Officer

In accordance with §13 of the DPDP Act, 2023:

**Grievance Officer**
Srinishtha Technologies Pvt. Ltd.
Email: grievance@srinishtha.com
Response time: Within 30 days of receipt

Unresolved complaints: **Data Protection Board of India**

---

## 14. Contact Us

**Srinishtha Technologies Pvt. Ltd.**

- Privacy queries: privacy@srinishtha.com
- Data deletion: Settings → Delete Account, or email privacy@srinishtha.com
- General support: Settings → Help & Support

---

*Vachika Lekhini v0.1.0 · Effective 22 June 2026*
