# Pizza Yard Website + Live Staff Order Dashboard

The existing Pizza Yard customer website is preserved. The current pricing, toppings, validation, ordering flow, and Formspree endpoint remain in place. The new dashboard uses Supabase Realtime.

## Files
- `index.html` — customer website
- `style.css` — existing customer styling
- `script.js` — existing ordering logic + Supabase insert
- `dashboard.html` — private staff login/dashboard
- `dashboard.css` — dashboard styling
- `dashboard.js` — authentication, Realtime, filters and status controls
- `supabase-setup.sql` — database, RLS, staff allow-list and Realtime
- `README.md` — setup instructions

## 1. Create Supabase project
Create a Supabase project, open **SQL Editor**, paste all of `supabase-setup.sql`, and run it.

## 2. Create staff login
In **Authentication → Users**, create the Pizza Yard staff email/password account. Copy its UUID, then in SQL Editor run:
```sql
insert into public.staff_users(user_id)
values ('PASTE_AUTH_USER_UUID_HERE');
```
Only authenticated users listed in `staff_users` can view/update orders. Do not enable public signup for dashboard staff.

## 3. Find Supabase values
Open **Project Settings → API**. Copy the **Project URL** and browser-safe **Publishable key**. Older projects may call the browser-safe key the **anon key**. Never use a service-role/secret key in frontend files.

## 4. Paste configuration
In `script.js`, replace:
```js
supabaseUrl: "YOUR_SUPABASE_PROJECT_URL",
supabasePublishableKey: "YOUR_SUPABASE_PUBLISHABLE_KEY"
```
In `dashboard.js`, replace:
```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_PUBLISHABLE_KEY = "YOUR_SUPABASE_PUBLISHABLE_KEY";
```
The Formspree endpoint remains `https://formspree.io/f/xdenabwa`.

## 5. GitHub Pages
Upload `index.html`, `style.css`, `script.js`, `dashboard.html`, `dashboard.css`, `dashboard.js`, `supabase-setup.sql`, and `README.md` to the repository root. Then **Settings → Pages → Deploy from a branch → main → /(root)**.

## 6. Dashboard URL
If the customer site is `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/`, open `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/dashboard.html`. Unauthenticated visitors see only the login screen.

## 7. Order behavior
Customer flow remains **Build Pizza → Enter Information → PLACE ORDER → ORDER RECEIVED**. The order is first saved to Supabase, then sent to Formspree as a backup. If Formspree fails after Supabase succeeds, the customer is still shown success and is not asked to resubmit. If Supabase fails, no success message is shown and entered information stays in the form.

## 8. Realtime behavior
The dashboard subscribes to `pizza_orders` using Supabase Realtime. New orders appear without refresh, are highlighted, automatically selected, and trigger `🍕 NEW PIZZA ORDER` plus an optional short sound. Sound On/Off is provided. The connection indicator shows `● Live` or `● Reconnecting…`.

## 9. Security
Anonymous users can only INSERT orders. There is no anonymous SELECT policy. Authenticated staff must also exist in `staff_users` to SELECT or UPDATE orders. No service-role/secret credential is used in frontend JavaScript.

## 10. Test
Verify:
- 1 topping = $20
- 2 toppings = $25
- 3 toppings = $28
- 4 toppings = $31
- 5 toppings = $34
- 6 toppings = $37
- quantity 2 + 2 toppings = $50
- quantity 3 + 2 toppings = $75
- quantity 3 + 2 toppings + delivery = $80
- quantity 3 + 3 toppings + delivery = $89
- delivery requires 3+ boxes
- delivery adds exactly $5
- pickup hides address
- invalid email/phone are blocked
- Formspree receives the backup email
- customer remains on Pizza Yard
- dashboard receives a new order without refresh
- status changes update immediately
- unauthenticated dashboard cannot see orders
