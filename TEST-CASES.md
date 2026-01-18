# Poptar WiFi Captive Portal - Test Cases

## Test Environment
- **Router:** MikroTik with Hotspot enabled
- **Session Timeout:** Configurable (default 30-60 min)
- **Test Devices:** iOS, Android (Pixel, Samsung, Redmi, Techno), Desktop

---

## STEP-01: Pre-Auth Welcome Page

### TC-01.1: Welcome Page Display
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-01.1.1 | Welcome page loads on WiFi connect | 1. Select "Poptar WiFi" from device WiFi list | Welcome page displays within 3 seconds | Critical |
| TC-01.1.2 | Page loads under 1MB | 1. Connect to WiFi 2. Check network tab | Total page size ≤ 1MB | High |
| TC-01.1.3 | No external JS blocking | 1. Disable external scripts 2. Load page | Page renders correctly without external JS | High |
| TC-01.1.4 | Brand visibility | 1. Load welcome page | "Poptar WiFi" branding clearly visible | High |

### TC-01.2: Connect Button
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-01.2.1 | Connect button visible | 1. Load welcome page | "Connect to Internet" button visible and prominent | Critical |
| TC-01.2.2 | Connect button clickable | 1. Tap "Connect to Internet" | Proceeds to authentication | Critical |
| TC-01.2.3 | Button responsive on mobile | 1. Test on various screen sizes | Button properly sized and tappable | High |

### TC-01.3: Ad/Banner Display
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-01.3.1 | Banner ad loads | 1. Load welcome page | Banner/ad content displays | Medium |
| TC-01.3.2 | Static content fallback | 1. Block ad network 2. Load page | Static fallback content shows | Medium |
| TC-01.3.3 | Impression tracking | 1. Load welcome page | Impression #1 recorded in analytics | High |

### TC-01.4: Language Toggle (Optional)
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-01.4.1 | Language toggle visible | 1. Load welcome page | BN/EN toggle visible | Low |
| TC-01.4.2 | Language switch works | 1. Click toggle | Content switches language | Low |

---

## STEP-02: Authentication

### TC-02.1: One-Tap Free Access
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-02.1.1 | One-tap connect works | 1. Click "Connect to Internet" | User authenticated without additional input | Critical |
| TC-02.1.2 | No credentials required | 1. Click connect | No username/password prompt | High |
| TC-02.1.3 | Authentication success | 1. Complete connect | User marked as authenticated in hotspot | Critical |

### TC-02.2: Authentication Failure Handling
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-02.2.1 | Retry on failure | 1. Simulate auth failure | Error message + retry option shown | High |
| TC-02.2.2 | Graceful error message | 1. Trigger auth error | User-friendly error (not technical) | Medium |

---

## STEP-02A: Post-Connect Splash Screen

### TC-02A.1: Splash Display
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-02A.1.1 | Splash appears after auth | 1. Complete authentication | Post-connect splash displays | Critical |
| TC-02A.1.2 | "Connected" message shown | 1. View splash | "You're now connected with Poptar WiFi" visible | High |
| TC-02A.1.3 | Ad content loads | 1. View splash | Static/HTML5/video ad displays | High |
| TC-02A.1.4 | Impression #2 tracked | 1. View splash | Second impression recorded | High |

### TC-02A.2: Continue Button
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-02A.2.1 | Continue button appears | 1. View splash after ad rules | "Continue Browsing" button visible | Critical |
| TC-02A.2.2 | Continue proceeds to video | 1. Click continue | Proceeds to STEP-03 video ad | Critical |

### TC-02A.3: Session Rules
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-02A.3.1 | Shows once per session | 1. Complete flow 2. Reconnect within session | Splash NOT shown again | High |
| TC-02A.3.2 | Does not block indefinitely | 1. Wait without interaction | Auto-proceeds after timeout | Medium |

---

## STEP-03: Non-Skippable 5-Second Video Ad

### TC-03.1: Video Playback
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-03.1.1 | Video auto-plays | 1. Reach STEP-03 | Video starts automatically | Critical |
| TC-03.1.2 | Video is muted | 1. Video plays | Audio muted by default | Critical |
| TC-03.1.3 | Full-screen display | 1. Video plays | Video covers full viewport | High |
| TC-03.1.4 | 5-second duration | 1. Time the video | Video/ad lasts exactly 5 seconds | Critical |

### TC-03.2: Non-Skippable Behavior
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-03.2.1 | No skip button during ad | 1. During 5-second ad | No skip/close button visible | Critical |
| TC-03.2.2 | Back button disabled | 1. Press back during ad | Ad continues, not skipped | High |
| TC-03.2.3 | Cannot close tab | 1. Try to close during ad | Ad persists or re-shows | Medium |

### TC-03.3: Countdown Display
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-03.3.1 | Countdown visible | 1. During ad playback | "Ad ends in 5...4...3..." visible | Critical |
| TC-03.3.2 | Countdown accurate | 1. Time countdown | Countdown matches actual time | High |
| TC-03.3.3 | Countdown style clear | 1. View countdown | Easy to read, not obstructive | Medium |

### TC-03.4: Post-Ad Redirect
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-03.4.1 | Auto-redirect after 5s | 1. Wait for ad to complete | Automatically redirects | Critical |
| TC-03.4.2 | Redirect to original URL | 1. Complete ad flow | Redirects to intended destination | High |
| TC-03.4.3 | Fallback to default page | 1. No original URL | Redirects to Google/landing page | Medium |

### TC-03.5: Sound Control
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-03.5.1 | Sound on tap | 1. Tap video during playback | Sound unmutes | Medium |
| TC-03.5.2 | Sound indicator | 1. View video | Mute/unmute icon visible | Low |

---

## Browsing Phase

### TC-04.1: Free Browsing
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-04.1.1 | Internet access works | 1. Complete flow 2. Browse websites | All websites accessible | Critical |
| TC-04.1.2 | Session timer runs | 1. Check session | Timer counts down from session limit | High |
| TC-04.1.3 | No repeated ads per page | 1. Navigate multiple pages | Ads only on reconnect, not per page | High |

---

## Reconnect Logic

### TC-05.1: Same Device Reconnect
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-05.1.1 | Skip STEP-03 within X hours | 1. Disconnect 2. Reconnect within time limit | Skips video ad, resumes browsing | High |
| TC-05.1.2 | Show STEP-02 on session expire | 1. Let session expire 2. Reconnect | Shows from STEP-02 | High |

### TC-05.2: New Device
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-05.2.1 | Full flow for new device | 1. Connect with new device | Complete STEP-01 → 02 → 02A → 03 | Critical |

### TC-05.3: MAC Randomization
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-05.3.1 | Treat randomized MAC as new | 1. Enable MAC randomization 2. Reconnect | Treated as new device | Medium |

---

## Device-Specific Tests

### TC-06.1: iOS
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-06.1.1 | CNA popup appears | 1. Connect to WiFi | Captive Network Assistant shows portal | Critical |
| TC-06.1.2 | CNA closes after auth | 1. Complete flow | CNA auto-closes, Safari opens | High |

### TC-06.2: Android
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-06.2.1 | Portal notification | 1. Connect to WiFi | "Sign in to network" notification | High |
| TC-06.2.2 | Manual browser fallback | 1. Open browser manually | Redirects to portal | High |

---

## Performance Tests

### TC-07.1: Load Time
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-07.1.1 | Pre-auth page < 3s | 1. Time page load | Loads within 3 seconds | High |
| TC-07.1.2 | Page size < 1MB | 1. Check total size | Under 1MB total | High |

### TC-07.2: Concurrent Users
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-07.2.1 | 30 simultaneous users | 1. Connect 30 devices | All see portal correctly | High |

---

## Analytics Tests

### TC-08.1: Tracking
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-08.1.1 | Session count accurate | 1. Complete multiple sessions | Session count matches | High |
| TC-08.1.2 | Impression #1 tracked | 1. Load STEP-01 | Pre-auth impression recorded | High |
| TC-08.1.3 | Impression #2 tracked | 1. View STEP-02A | Post-auth impression recorded | High |
| TC-08.1.4 | Video completion tracked | 1. Complete STEP-03 | 100% completion recorded | High |
| TC-08.1.5 | Device/OS split | 1. Check analytics | Device type identified | Medium |

---

## Compliance Tests (Bangladesh)

### TC-09.1: Content Compliance
| ID | Description | Steps | Expected Result | Priority |
|----|-------------|-------|-----------------|----------|
| TC-09.1.1 | No medical claims | 1. Review ad content | No diagnostic/healing claims | Critical |
| TC-09.1.2 | No prohibited content | 1. Review ads | No gambling/adult/alcohol | Critical |
| TC-09.1.3 | Political labeling | 1. Check political content | Labeled as "Awareness/Public Message" | High |
| TC-09.1.4 | Minimal data collection | 1. Check forms | Phone optional, minimal fields | High |
