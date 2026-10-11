# Namma Fresh Bakes: ordering site template

A single-file website (`index.html`) for a small food business. Customers browse the menu, add items to a cart, fill in delivery details, and send the order to the shop on WhatsApp. No build step, no backend.

## Customise it for a new client

Open `index.html`. Edit **only** the first script block, right after the opening `<body>` tag.

**CONFIG**

| Field | What it does |
| --- | --- |
| `shopName` | Page title, header, and the first line of the WhatsApp message |
| `tagline` | Line under the shop name |
| `whatsapp` | Shop's number with country code, digits only (e.g. `919876543210`) |
| `area` | Footer text (delivery area, lead time) |
| `leadDays` | Earliest delivery date = today + this many days |
| `maxDays` | Furthest date a customer can pick = today + this many days (default 60) |
| `askDeliveryDate` | `false` hides the date and time fields and leaves them out of the message |
| `timeSlots` | Choices in the preferred-time dropdown. Use `[]` to hide the time field |
| `minOrder` | Minimum items total in rupees. Below it, checkout is blocked with a friendly message. `0` = no minimum |
| `deliveryCharge` | Added to Delivery orders (not Pickup). `0` = free delivery |
| `cutoffMessage` | Short note shown at the top of the cart panel. `""` hides it |
| `supabaseUrl` | The client's Supabase Project URL. `""` = use only the built-in `MENU` (no database) |
| `supabaseKey` | The client's Supabase **publishable** key (`sb_publishable_...`). Never the secret key |
| `saveOrders` | `true` saves each order in Supabase (needed for the orders dashboard). `false` = WhatsApp only, nothing is stored |
| `privacyNote` | One line shown above the Place order button when orders are saved. Edit it to match what the shop really does with the data |
| `privacyUrl` | Link shown after the privacy note, to the shop's privacy page. `""` = no link |
| `colors` | `main`, `accent` and `background` brand colours (keep the background light) |

Customers choose **Delivery** or **Pickup**. The address field only appears, and is only required, for Delivery. The date and time labels change to match.

**MENU**: the built-in menu. When Supabase is set up, the live menu comes from the database and this list is only the fallback if it can't be reached. Each line has: one line per item: `id`, `name`, `category`, `price` (rupees), `description`, `available`. Items with the same `category` text are grouped together. Set `available: false` to show "Sold out".

## Menu from Supabase (one project per client)

1. Create a Supabase project for the client, run the `menu_items` table SQL, and load their menu.
2. Create the owner's login under Authentication, Users, and switch off public sign-ups.
3. Copy the Project URL and the publishable key into `CONFIG`.
4. The page shows "Loading menu…" while it fetches. If the database can't be reached, it shows the built-in `MENU` and a notice that prices may be out of date.
5. Free Supabase projects pause after a week with no activity. Fine for demos. For a paying client, use a paid plan or keep the project active.

## Saving orders (Week 3)

Run `supabase-orders.sql` once per client in the Supabase SQL Editor, after replacing `PASTE-OWNER-UID` with the owner's User UID. It creates the `orders` and `shop_settings` tables, an `is_owner()` check, and a `place_order()` function.

- With `saveOrders: true`, the cart button says **Place order**. It saves the order first, then shows the order number and a **Send on WhatsApp** button. The WhatsApp message includes that number.
- If saving fails (no network, paused project, function missing), the customer is offered the old WhatsApp-only button, so no order is lost.
- Customers cannot read or change orders. The database looks up prices itself, so a customer cannot send a lower price. It also refuses sold-out items, orders below the minimum, and more than 5 orders per phone per hour.
- `shop_settings` holds `min_order`, `delivery_charge` and `accepting_orders`. Keep `min_order` and `delivery_charge` equal to `minOrder` and `deliveryCharge` in `index.html` CONFIG. To stop taking online orders, set `accepting_orders` to false in Table Editor.
- Orders contain customers' names, phone numbers and addresses. Tell the client, keep the privacy note accurate, and delete old orders you no longer need.

## Owner admin page (`admin.html`)

One page, one login, two tabs.

**Orders tab** (opens first): the orders saved by the Place order button.
- Filters: **To do** (new, confirmed, ready), **Today**, **Done** (completed and cancelled), **All**. Each shows a count.
- Each order shows the number, status, customer name and phone, delivery or pickup, date and time slot, address, notes, items with line totals, delivery charge and total.
- Status buttons: **Confirm order**, then **Mark ready**, then **Mark completed**. **Cancel order** needs a second tap to confirm. Done orders can be **Reopened** or **Deleted** (second tap to confirm).
- **Call** and **WhatsApp** buttons for the customer. The WhatsApp message is filled in to match the order's status.
- A switch at the top turns **Accepting online orders** on or off.
- The page checks for new orders every 30 seconds while it is open and visible, and again when the owner comes back to it. A badge on the tab and in the page title shows how many are new. It cannot send phone notifications, so the WhatsApp message from the customer is still the instant alert.

**Clear old orders** (at the bottom of the Orders tab): the owner picks 30, 60, 90 or 180 days. The first tap counts the finished orders that old, and the second tap deletes them. Only completed and cancelled orders are deleted.

**Menu tab**: change name, price, category and description, switch items between Available and Sold out, add new items, delete items (two taps to confirm).

Setup:
- Put `admin.html` and `supabase-js.umd.js` in the same folder and repo as `index.html`. After deploying it lives at `your-site-link/admin.html`. `admin.html#menu` opens the Menu tab.
- Fill in the same `CONFIG` fields: `shopName`, `supabaseUrl`, `supabaseKey` (publishable key only).
- The owner's login is created by you in Supabase under Authentication, Users. Keep public sign-ups switched off.
- The page asks search engines not to index it, but the link is not a secret. The login is what protects the data: only the owner can read orders or change the menu, enforced by the rules in Supabase.
- If the owner forgets their password, reset it from Authentication, Users in the Supabase dashboard.

## Privacy and keeping order data (Week 3)

Saved orders hold customers' names, phone numbers and addresses, so for every client:

1. Copy `privacy.html` next to `index.html` and edit its `CONFIG` block (shop name, WhatsApp number, retention days, last-updated date). `index.html` links to it from the note above the Place order button (`privacyUrl`).
2. Turn on the **pg_cron** extension in Supabase (Database, Extensions) and run `supabase-retention.sql` once. It deletes finished orders after 90 days and any order after 180 days, every night. If you change those numbers, change `retentionDays` and `unfinishedDays` in `privacy.html` too, so the page stays true.
3. Tell the client in plain words what is stored and for how long, and that a customer can ask them to show, correct or delete their details. The owner can delete a single order from the Done list.
4. This is not legal advice. India's Digital Personal Data Protection Act, 2023 and its 2025 rules introduce duties around privacy notices, security and erasing data that is no longer needed, with the main duties starting in 2027. Check the current position, and what applies to the client's size, with a qualified adviser.

## Security checklist (do this for every client)

**Files**
- `supabase-js.umd.js` is the Supabase library, version 2.110.9 (MIT licence), copied unchanged from npm (SHA-256 `0ced6b6a809cebaf1869c87cb5e690fddf7235d2a7cc5a951d06b54d0832bf9b`). It sits next to `admin.html` and is served from your own site. To update it, download a newer release from npm, replace the file, and test the login again.
- `_headers` is read by Netlify. It stops the site being shown inside another page and sets safe browser defaults. It must be named exactly `_headers`, with no `.txt` on the end.

**In the Supabase dashboard**
1. Authentication, Sign In / Providers: **Allow new users to sign up** is OFF.
2. The same page: **Allow anonymous sign-ins** is OFF. Anonymous users count as "logged in" to the database rules.
3. Set a minimum password length of 10 or more, and use a long password for the owner.
4. Optional: turn on multi-factor authentication for the owner.
5. Only the **publishable** key is ever used in the HTML files. The secret key never leaves the Supabase dashboard.

**Lock editing to the owner and limit what can be saved.** In Authentication, Users, copy the owner's **User UID**. In the SQL Editor, run this with the UID pasted over each `PASTE-OWNER-UID`:

```sql
drop policy "Logged-in admin can add items" on menu_items;
drop policy "Logged-in admin can edit items" on menu_items;
drop policy "Logged-in admin can delete items" on menu_items;

create policy "Owner can add items" on menu_items for insert to authenticated
  with check ((select auth.uid()) = 'PASTE-OWNER-UID'::uuid);
create policy "Owner can edit items" on menu_items for update to authenticated
  using ((select auth.uid()) = 'PASTE-OWNER-UID'::uuid)
  with check ((select auth.uid()) = 'PASTE-OWNER-UID'::uuid);
create policy "Owner can delete items" on menu_items for delete to authenticated
  using ((select auth.uid()) = 'PASTE-OWNER-UID'::uuid);

alter table menu_items
  add constraint price_range check (price between 1 and 100000),
  add constraint name_length check (char_length(name) between 1 and 80),
  add constraint category_length check (char_length(category) between 1 and 40),
  add constraint description_length check (description is null or char_length(description) <= 200);
```

**Test that a stranger cannot write.** Open the public site, press F12, choose Console, and paste:

```js
fetch(CONFIG.supabaseUrl + "/rest/v1/menu_items", {method: "POST", headers: {apikey: CONFIG.supabaseKey, "Content-Type": "application/json"}, body: JSON.stringify({name: "RLS TEST delete me", category: "Test", price: 1})}).then(r => r.json()).then(console.log)
```

The answer must contain `42501` (a row-level security error). If it returns a new row instead, the rules are wrong. Delete that test row in Table Editor and fix the policies.

**Remember:** the WhatsApp message is typed by the customer's own phone, so its prices and totals are not verified. The shop should check totals against its own menu.

## Test before sharing

1. Open `index.html` in a browser (phone view too).
2. Add items, open the cart, fill in the details, tap **Send order on WhatsApp**.
3. Check the message arrives with the items, total, and delivery details.

## Deploy

1. Create a new GitHub repo for the client.
2. In the folder: `git init`, `git add index.html README.md`, `git commit -m "First version"`, then `git remote add origin <repo link>`, `git branch -M main`, `git push -u origin main`.
3. In Netlify: **Add new project**, **Import an existing project**, **GitHub**, pick the repo. Leave build command and publish directory empty, then **Deploy**.
4. To update the menu later: edit, then `git add`, `git commit`, `git push`. The site updates in about a minute.

## Notes

- The cart is saved in the customer's browser, so a refresh keeps it. Items that are removed from the menu or marked sold out are dropped when the page loads. The cart is cleared after the customer taps the WhatsApp button, and a **Restore cart** button appears for 12 seconds in case they didn't send the message.
- The page can't know if the customer actually taps Send in WhatsApp, so the confirmation message tells them to.
- On Android, the Back button closes the open cart instead of leaving the site.
- Field limits: name 60, address 250, notes 300 characters. This keeps the WhatsApp link a safe length.
- If `whatsapp` is a personal number, replace it before sharing a demo link publicly. Orders go to that number.
