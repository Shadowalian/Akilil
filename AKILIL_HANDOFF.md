# Akilil — Full Context Handoff Guide

> **Audience:** marketing managers, sales managers, new managers, partnerships, customer success, ops leads, and anyone joining the team who must explain Akilil in detail.  
> **Last updated:** November 2026  
> **Status:** Private beta · built in Addis Ababa  

**If you only have five minutes:** read **§1**, **§3 (the three pillars)**, **§4**, and **§12**.  
**If you are marketing or a new manager:** read the whole document once; the pillars section is non-negotiable.

---

## 1. Elevator pitch (30–60 seconds)

**Akilil** is an Ethiopia-first human platform with **three paths** people choose when they open the app:

1. **Spiritual Psychiatry** — faith-aware mental care  
2. **Psychiatry** — licensed clinical support  
3. **Cooking** — live classes with chefs  

Across all three, people connect with **verified humans** (not chatbots) by chat, voice, or video — in **Amharic, Afaan Oromo, Tigrinya, or English** — then keep a private journal and return for the next session.

It is **not an emergency service**.  
It is **not “only therapy.”** Care of the mind, faith-aware support, and nourishing live cooking sit under one brand because real life in Ethiopia mixes those needs.

**Tagline energy:** *A friend when you need a human.*  
**Product line in the app:** *Spiritual Psychiatry · Psychiatry · Cooking*

---

## 2. Who this document is for (and what each role must know)

| Role | Must understand deeply | Can skim |
|------|------------------------|----------|
| **Marketing manager** | Pillars, brand voice, audiences per pillar, claims vs safety limits, campaign angles | Backend stack |
| **Sales / partnerships** | Pillars, ICP, pricing honesty, demo script, objections | Schema / migrations |
| **New manager (any dept)** | What Akilil is, three pillars, journeys, what’s live vs marketed | Code folders |
| **CS / support** | Journeys, safety disclaimer, verification, refunds/payouts narrative | Design tokens |
| **Investors / advisors** | Pitch, market story, monetization, truth table | UI file names |

This is **not a sales-only sheet**. Marketing owns how the three pillars are told in public; sales uses the same truth.

---

## 3. The three Akilil pillars (core product — know this cold)

In the product code and UI, these are the **only practice areas**. Discovery, assessment (“choose your path”), and pro onboarding all route through them.

| Pillar | Slug (systems) | Subtitle (EN) | Subtitle (Amharic concept) | Who shows up as the “pro” |
|--------|----------------|---------------|----------------------------|---------------------------|
| **Spiritual Psychiatry** | `spiritual-psychiatry` | Faith-aware mental care | በእምነት የተደገፈ የአእምሮ እንክብካቤ | Spiritual guides, faith-literate counselors, practitioners who hold mind + belief with respect |
| **Psychiatry** | `psychiatry` | Licensed clinical support | በፈቃድ የተደገፈ ክሊኒካዊ ድጋፍ | Licensed psychologists / psychiatrists / clinical counselors (credential-checked) |
| **Cooking** | `cooking` | Live classes with chefs | ከሼፎች ጋር የቀጥታ ትምህርቶች | Chefs and culinary teachers running live sessions |

Default path in-app if none chosen: **Psychiatry**.

### 3.1 Spiritual Psychiatry — in depth

**What it is**  
Care that takes faith, meaning, and spiritual life seriously alongside mental wellbeing. Not a replacement for hospital psychiatry. Not a sermon app. A place to talk with someone who will not mock prayer, ritual, or religious language — and who still practices ethical, grounded support.

**Who it is for (clients)**  
- People who want mind-care without leaving their faith at the door  
- Those who find purely secular clinic language alienating  
- Families navigating guilt, grief, vocation, or community pressure in spiritual terms  

**Who we recruit (supply)**  
Spiritual guides, faith-aware counselors, trained listeners who work in Ethiopian religious/cultural contexts (Orthodox, Muslim, Protestant, and other communities — product is **faith-aware**, not single-denomination locked).

**Marketing angle**  
“Faith-aware mental care — human, verified, in your language.”  
Do **not** claim Akilil is a church, mosque, or diagnostic spiritual authority.

**Sales / partnership angle**  
Faith communities, chaplaincy networks, counseling training houses that already do spiritual care and need digital scheduling + video.

**Safety note for copy**  
Spiritual Psychiatry still uses the global rule: **not an emergency service**. Crisis → local emergency / crisis lines. Do not market “prayer instead of ER.”

### 3.2 Psychiatry — in depth

**What it is**  
Licensed clinical support: the classic mental-health path — psychologists, psychiatrists, clinical counselors — matched by language and need, booked into private sessions.

**Who it is for (clients)**  
- Burnout, anxiety, depression symptoms, life transitions, relationship strain  
- People who want a **credentialed** clinician with a verified badge  
- Anyone who chose “Psychiatry” on the path picker  

**Who we recruit (supply)**  
Licensed clinical professionals practising in Ethiopia or with Ethiopian clients abroad. Verification includes identity + licence/documents + admin approval.

**Marketing angle**  
“Licensed clinical support on your phone — verified humans, private sessions.”  
Avoid: diagnose, cure, prescribe (unless a real licensed psychiatrist workflow is explicitly live and legal — do not invent it in ads).

**Sales / partnership angle**  
Clinics, universities, employers (EAP-style), NGOs focused on mental health access.

**Safety note for copy**  
Same crisis disclaimer. Do not position Akilil as inpatient, hospital, or replacement for psychiatric emergency care.

### 3.3 Cooking — in depth (chefs)

**What it is**  
Live classes with **chefs** — real-time teaching over Akilil Meet (video/voice), not a recipe blog and not a passive YouTube dump. Same booking / wallet / session shell as care pillars, different craft.

**Why it sits inside Akilil**  
Wellbeing is not only talk therapy. Shared food, skill, rhythm, and community are culturally central. Cooking is a **third door** for people who will never open a “mental health” app but will join a live class — and a growth/marketing differentiator.

**Who it is for (clients)**  
- Home cooks who want live instruction  
- People seeking structured, joyful live sessions (not clinical intake-heavy)  
- Diaspora / local users who want Ethiopian (or other) cuisine taught live  

**Who we recruit (supply)**  
Chefs, culinary teachers, cooking coaches — verified as practitioners for the Cooking pillar (licence rules differ from Psychiatry; warmth + skill + safety still matter).

**Marketing angle**  
“Live classes with chefs — book a seat, cook together on video.”  
Do **not** bury Cooking under “therapy” in campaigns. Give it its own creative when needed; still brand it Akilil.

**Sales / partnership angle**  
Culinary schools, restaurant groups, food influencers as pros, lifestyle brands, wellness retreats that include cooking.

**Product truth**  
Cooking uses the **same** discovery → book → Meet → wallet machinery. Marketing should not invent a separate “Cooking app”; it is a **pillar inside Akilil**.

### 3.4 How pillars show up in the product (so managers can demo)

1. **Assessment / path** — user picks Spiritual Psychiatry, Psychiatry, or Cooking  
2. **Today / Discover** — pillar cards / carousel; filters stay inside the chosen path  
3. **Pro onboarding** — professionals pick which pillar they practice  
4. **Matching** — clients see pros in that pillar (plus language, price, badge filters)

If marketing or sales talks about “categories,” use the word **pillars** — that is the product language.

---

## 4. What Akilil is / is not

### It is
- A **three-pillar** marketplace + care/learning shell: Spiritual Psychiatry · Psychiatry · Cooking  
- Multilingual matching (language-first)  
- Live sessions via **Akilil Meet** (chat / voice / video)  
- Self-care tools: journal, mood, goals/habits, worksheets, crisis resources  
- Admin tools: verify pros, crisis flags, moderation, money/payouts  

### It is not
- Only a psychiatry clinic app (Cooking and Spiritual Psychiatry are first-class)  
- A chatbot therapist  
- An emergency / ambulance / inpatient service  
- A passive recipe site or sermon archive  
- A Western wellness clone with Ethiopia as an afterthought  

**Always say out loud:**  
*“Akilil is not an emergency service. If someone is in immediate danger, contact local emergency services or a crisis line.”*

---

## 5. Who we serve (by pillar + role)

### A. End clients
| Need | Likely pillar |
|------|----------------|
| Faith-aware talk / meaning / spiritual strain | Spiritual Psychiatry |
| Licensed clinical talk | Psychiatry |
| Learn to cook live with a chef | Cooking |
| Private journal / mood between sessions | All (companion tools) |

**Jobs to be done**
1. “I need a human in my language — today.”  
2. “I want the same person (or chef) next week.”  
3. “I want a path that fits who I am — faith, clinic, or kitchen.”  

### B. Professionals (supply — by pillar)
| Pillar | Typical pro |
|--------|-------------|
| Spiritual Psychiatry | Spiritual guides, faith-aware counselors, trained peer listeners in faith contexts |
| Psychiatry | Licensed psychologists / psychiatrists / clinical counselors |
| Cooking | Chefs, culinary instructors |

**Shared pro jobs:** fill slots, host Meet, get paid in a predictable way, less admin.

### C. Platform ops
Verify credentials (rules differ by pillar), crisis review, community moderation, refunds, payouts.

### D. External partners (marketing + sales)
| Segment | Pillars they usually care about |
|---------|----------------------------------|
| Faith communities / chaplaincy | Spiritual Psychiatry |
| Clinics, universities, EAP buyers | Psychiatry (+ sometimes Spiritual) |
| Culinary schools, F&B brands | Cooking |
| Telco / payments (Chapa, Telebirr) | All (distribution + rails) |
| NGOs | Often Psychiatry + Spiritual; Cooking for community programs |

---

## 6. Market story (why Akilil exists)

Hard conversations in Ethiopia often happen over **buna**, with someone trusted. That works until you move cities, the topic is taboo, or nobody is free.

Akilil’s answer is broader than “import BetterHelp”:
- **Psychiatry** for credentialed care  
- **Spiritual Psychiatry** so faith is not stripped out of healing  
- **Cooking** so wellbeing includes skill, joy, and live human teaching  

Same bridge idea: empty calendars on the supply side ↔ people who will join a phone/video session who will never walk into an office.

---

## 7. Feature map (what the product *does*, across pillars)

| Feature area | Client | Pro |
|--------------|--------|-----|
| **Choose pillar** | Path / Discover cards | Onboarding category = pillar |
| **Match & book** | Filters, slots, listening requests | Availability, queue, walk-in |
| **Akilil Meet** | Waiting room → live session | Host session |
| **Wallet & pay** | Top up, booking debit | Earnings, payouts |
| **Reflect** | Journal, mood, worksheets | Notes / client dossier (esp. clinical) |
| **Safety** | SOS / Crisis center | Flags → admin humans |
| **Community** | Moderated rooms (where live) | Same network |

**Three surfaces**
1. **Akilil** — client app  
2. **Akilil Pro** — professional app  
3. **Akilil Admin** — web `/admin`  

Plus marketing site (how it works, pricing, safety, for professionals, download).

---

## 8. Journeys (walkthroughs for demos & onboarding)

### Client (all pillars share the spine)
1. Sign up → optional assessment → **choose path** (Spiritual Psychiatry / Psychiatry / Cooking)  
2. Discover pros/chefs in that pillar  
3. Wallet top-up if paid  
4. Book (or free listening where offered)  
5. Pre-flight → **Akilil Meet**  
6. After: journal / review / return  

### Professional
1. Apply → pick pillar → documents  
2. Admin verifies  
3. Availability  
4. Command Center → Launch Meet  
5. Notes / dossier (heavier for clinical pillars)  
6. Payout request  

### Marketing-specific journey (campaign → install)
1. Creative names the **pillar** clearly (don’t mush “therapy + chefs” into one confusing ad without structure)  
2. Landing / store → install  
3. First-session prompt: **Choose your path**  
4. Measure conversion **per pillar**, not only “total installs”

---

## 9. Money model (say carefully)

### Consumer story (marketing)
- Free to start: journal / community / intro conversation (as marketed)  
- Pay for a **person’s live time** (clinician, spiritual guide, or chef)  
- Local rails story: **Telebirr + Chapa**, prices in **ETB**  
- Site list prices are **beta placeholders** (e.g. free / ~899 / ~2,400 ETB monthly ideas) — lock only with product/finance  

### Mechanics
Wallet top-up → booking debit → pro earnings → admin-approved payouts → platform fee.

### Honesty rule for marketing & sales
Do **not** promise live Telebirr/Chapa checkout in a contract or ad until product confirms it is live for that build. Prefer: *“Wallet-based payments; Ethiopian rails in rollout / confirm current methods.”*

Cooking sessions are monetized the same way as care sessions unless product says otherwise — **do not invent a separate chef marketplace fee story**.

---

## 10. Trust, privacy, safety

- Pros verified before clients meet them (documents + admin; intensity depends on pillar)  
- Verified badge in UI  
- Crisis disclaimer always  
- Crisis content flags → **human** review (no auto-ambulance)  
- Don’t sell data; don’t claim hospital-grade EMR unless true  

### Objection cheat sheet (include Cooking & Spiritual)

| Objection | Response |
|-----------|----------|
| “Is this only therapy?” | No — three pillars: Spiritual Psychiatry, Psychiatry, and live Cooking with chefs. |
| “Is Cooking a gimmick?” | No — same live human session product; food and skill are part of wellbeing and culture. |
| “Is Spiritual Psychiatry religious marketing?” | Faith-**aware** care with verified humans — not a single-religion megachurch product. |
| “AI therapist?” | No. Humans. |
| “Emergency?” | No. Crisis lines / emergency services for immediate danger. |
| “Pay in birr?” | Intent yes; confirm live methods this week. |

---

## 11. Competitive & category positioning

| vs… | Akilil |
|-----|--------|
| AI chatbots | Real people; three human pillars |
| Clinic-only | Digital access + language + evenings + Cooking door |
| Pure therapy apps | Adds **Spiritual Psychiatry** + **Cooking** |
| Recipe YouTube | Live booked chefs, not passive video |
| US teletherapy clones | Ethiopia-first languages + local trust + multi-pillar |

**Category line for decks:**  
*Ethiopia-first human wellbeing platform — faith-aware care, licensed clinical support, and live cooking — on one app.*

---

## 12. Brand & messaging (marketing managers)

### Voice
Calm · trustworthy · warm · honest about limits.

### Words we like
Pillars, path, listen, match, sanctuary, verified, private, language, human, chef, faith-aware, live class.

### Words we avoid
Cure, diagnose (as ad claim), AI therapist, “replace hospital,” panic CTAs, burying Cooking as a footnote when the campaign is about Cooking.

### Creative system (practical)
- **Master brand:** Akilil  
- **Sub-lines:** one campaign stream per pillar when scale allows  
- **Always** show path clarity in screenshots (pillar cards / “Choose your path”)  
- Safety footer on clinical/spiritual ads  

### Visual
Clinical teal sanctuary UI (Stitch), glass headers, SOS chip — professional, not childish; Cooking creatives can be warmer/food-forward but still Akilil, not a random food brand.

---

## 13. What’s live vs forming (truth table)

| Area | Status | What you can say |
|------|--------|------------------|
| Three pillars in client/pro UI | **Built** | Spiritual Psychiatry · Psychiatry · Cooking |
| Book + Meet + wallet UI | **Built / beta** | Demo end-to-end |
| Pro Command Center / dossier | **Built / beta** | Demo host + notes |
| Admin verify / crisis / payouts | **Built** | Ops can run |
| Amharic strings for pillar names | **Present** | Full UI language coverage still rolling |
| Chapa / Telebirr live checkout | **Confirm before promising** | Marketed intent |
| Pillar-specific verification depth | **Evolving** | Clinical docs stricter than chef portfolios |
| Enterprise packages | **Opportunity** | Packaging, not self-serve |

---

## 14. Demo scripts

### A. Sales / partnerships (15 min)
1. Problem (buna + empty calendars)  
2. Show **three pillars** on path / Discover  
3. Pick **Psychiatry** → book → Meet  
4. Flip to Pro Command Center  
5. Mention Spiritual + Cooking as equal doors  
6. Safety + pricing honesty  

### B. Marketing / new manager (20 min)
1. Brand story + what we are not  
2. Deep dive each pillar (who / message / don’ts)  
3. Walk client path picker → Discover cards  
4. Show chef session narrative vs clinical session narrative  
5. Review live vs marketed truth table  
6. Agree campaign claims for this week with product  

---

## 15. Metrics that matter (by audience)

**Shared:** installs → path chosen → first booked session → second session with same pro/chef  

**Per pillar (marketing must track separately):**
- Path selection mix (Spiritual % / Psychiatry % / Cooking %)  
- Conversion to first session per pillar  
- Supply fill rate per pillar (are there enough chefs? enough clinicians?)  

**Ops:** verification SLA, crisis flag handling time, payout cycle time  

---

## 16. Org ownership

| Role | Owns |
|------|------|
| **Marketing** | Pillar messaging, campaigns, site copy, creative per pillar, waitlist |
| **Sales / partnerships** | Demos, NGO/employer/clinic/culinary deals, pro recruitment partnerships |
| **Product** | Pillar rules, payments, language UX, verification policy differences |
| **Clinical advisor** | Psychiatry + Spiritual scope language, safety |
| **Culinary advisor / lead** (if appointed) | Chef standards, Cooking quality |
| **Ops / support** | Verification queues by pillar, crisis, refunds, payouts |
| **Engineering** | Apps, API, Meet, admin |

---

## 17. FAQ

**Is Akilil only mental health?**  
No. Three pillars: Spiritual Psychiatry, Psychiatry, and Cooking (live chefs).

**Why Cooking inside a care brand?**  
Wellbeing includes skill, food, and live human teaching. Same session infrastructure; different craft. It also opens a door for users who avoid “therapy” labels.

**Is Spiritual Psychiatry the same as Psychiatry?**  
No. Faith-aware mental care vs licensed clinical support. Different messaging and often different credentials. Same app shell.

**Do chefs need a medical licence?**  
No — but they still go through onboarding + verification appropriate to Cooking. Don’t imply chefs are clinicians.

**Same app for clients and pros?**  
No. **Akilil** vs **Akilil Pro**.

**Pricing final?**  
No — beta placeholders until finance/product lock.

**Old name “Friend”?**  
Internal/legacy only. Customer-facing name is **Akilil**.

---

## 18. Day-one checklist (new manager / marketing / sales)

- [ ] Read §§1–5 and §12 fully  
- [ ] Memorize the three pillars and one-line subtitles  
- [ ] Open the client app and complete **Choose your path** for each pillar  
- [ ] Find at least one pro profile under each pillar (or note supply gaps)  
- [ ] Walk marketing site + Safety page  
- [ ] Learn crisis disclaimer  
- [ ] Confirm live payment methods with product  
- [ ] Marketing: draft one headline per pillar that does not overclaim  
- [ ] Sales: dry-run 15-min demo including all three pillars  

---

## 19. Related files

| Path | Why |
|------|-----|
| `AKILIL_HANDOFF.md` | **This guide** — business, marketing, sales, manager context |
| `friend-flutter/packages/core/lib/src/theme/akilil_pillars.dart` | Canonical pillar definitions in product |
| `ARCHITECTURE.md` / `SCHEMA.md` | Engineering |
| `STYLE_GUIDE.md` | Visual tokens |
| `designs/stitch-akilil/` | UI designs |
| `friend-backend/resources/views/marketing/` | Public marketing copy |

---

**Bottom line for handoff:**  
Akilil is **one brand, three doors** — **Spiritual Psychiatry**, **Psychiatry**, and **Cooking with live chefs** — connecting verified humans in Ethiopian languages. Marketing tells each door clearly; sales demos the shared booking/Meet/wallet spine; every manager knows the crisis limit: we are not emergency care, and we are not a chatbot.
