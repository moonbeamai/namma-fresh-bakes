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
| `privacyNote` | Optional sentence shown before the privacy link above the Place order button. Empty by default, so only the **Privacy details** link shows |
| `privacyUrl` | Link shown after the privacy note, to the shop's privacy page. `""` = no link |
| `pausedMessage` | The banner customers see when the owner switches **Accepting online orders** off |
| `colors` | `main`, `accent` and `background` brand colours (keep the background light) |

Customers choose **Delivery** or **Pickup**. The address field only appears, and is only required, for Delivery. The date and time labels change to match.

**MENU**: the built-in menu. When Supabase is set up, the live menu comes from the database and this list is only the fallback if it can't be reached. Each line has: one line per item: `id`, `name`, `category`, `price` (rupees), `description`, `available`. Items with the same `category` text are grouped together. Set `available: false` to show "Sold out".

## Menu from Supabase (one project per client)

1. Create a Supabase project for the client, run the `menu_items` table SQL, and load their menu.
2. Create the owner's login under Authentication, Users, and switch off public sign-ups.
3. Copy the Project URL and the publishable key into `CONFIG`.
4. The page shows "Loading menu…" while it fetches. If the database can't be reached, it shows the built-in `MENU` and a notice that prices may be out of date.
5. Free Supabase projects pause after a week with no activity. Fine for demos. For a paying client, use a paid plan or keep the project active.

## The storefront design (Week 4)

`index.html` is a full storefront: a sticky header (round logo, shop name, Menu, Visit, Basket with a count), a hero with a big headline (second line in italic), a three-step strip on a lighter, dotted full-width band, a menu of photo cards with category pills, a pick-up section, and a footer with a **Staff** link to the admin page. It works on phones and computers. On a phone the sticky bottom bar shows the basket total; on a computer the header Basket button is used.

**Per client, edit the `CONFIG` block** (everything below is plain text in one place):
- `colors`: `main` (dark brown), `accent` (amber labels), `background` (cream) and `caramel` (Add to basket buttons and the italic headline words).
- `logoLetter`, `navMenu`, `navVisit`, `navBasket`, and `addLabel` (the text on each card's button, "Add to basket").
- `hero`: `pill`, `line1`, `line2` (the italic line), `text`, `cta1`, `cta2`, `image` (photo link, or empty for a drawing), `cardTitle`, `cardSub` and `cardSubNoFree`.
- `steps`: three steps, each with an `icon` (basket, clock or wallet), `title` and `text`. In `text`, `{ahead}` becomes the real ordering window (from `leadDays` and `maxDays`, for example "Same day or up to 7 days ahead.") and `{freeLine}` becomes "Free delivery over ₹500." from the shop's Settings. If there is no free delivery amount, that sentence is left out.
- `menuEyebrow`, `menuTitle`.
- `visit`: `eyebrow`, `title`, `text`, `lines` (each with an `icon`: clock, pin or oven, and `text`) and `image`. Leave `title` empty and `lines` empty to hide the section and the Visit link.
- `footerTagline`, `staffLabel` (empty hides the Staff link), and `area` (the delivery note in the footer).
- Set `leadDays: 0` and `maxDays: 7` for "same day or up to a week ahead".

**Menu photos, badges and unit labels.** Run `supabase-menu-extras.sql` once per client. It adds three optional columns to `menu_items`: `image_url` (a link starting with `https://`, or `images/...` for a file in the site's images folder), `badge` (up to 30 letters, shown on the photo) and `unit_label` (up to 40 letters, shown under the name, like BOX OF 4). The owner edits them in the admin Menu tab, which shows a small preview of the photo. Without a photo the card shows a drawing, and a link that fails to load also falls back to the drawing. The database refuses unsafe links.

**Pictures.** The drawings and the placeholder text in `CONFIG` are only placeholders. Use the client's own photos, logo and wording. Do not reuse another business's photos or text. Photo links can point to any https image address. The first version of the admin takes a link; uploading photos from the admin page is a later step.

## Saving orders (Week 3)

Run `supabase-orders.sql` once per client in the Supabase SQL Editor, after replacing `PASTE-OWNER-UID` with the owner's User UID. It creates the `orders` and `shop_settings` tables, an `is_owner()` check, and a `place_order()` function.

- With `saveOrders: true`, the cart button says **Place order**. It saves the order first, then shows the order number and a **Send on WhatsApp** button. The WhatsApp message includes that number.
- If saving fails (no network, paused project, function missing), the customer is offered the old WhatsApp-only button, so no order is lost.
- Customers cannot read or change orders. The database looks up prices itself, so a customer cannot send a lower price. It also refuses sold-out items, orders below the minimum, and more than 5 orders per phone per hour.
- `shop_settings` holds the shop's rules: `min_order`, `delivery_charge`, `accepting_orders` and the payment settings below. The page reads them from there, so changing a value in Table Editor changes the shop straight away. `minOrder` and `deliveryCharge` in `index.html` CONFIG are only used if the settings can't be read. The owner can also pause orders from the admin page.
- **Pausing:** when the owner switches **Accepting online orders** off in the admin, customers see the `pausedMessage` banner at the top of the page as soon as it opens (and again if they tap Add after the switch changed). Every Add button becomes "Not taking orders", and there is no Place order button and no WhatsApp button, so there is no way to order. The page re-checks when it opens, when the cart is opened, when something is added after 30 seconds, and when the customer returns to the tab. The database also refuses orders while paused. This switch only exists for shops that save orders (`saveOrders: true`).
- Orders contain customers' names, phone numbers and addresses. Tell the client, keep the privacy note accurate, and delete old orders you no longer need.

## Owner admin page (`admin.html`)

One page, one login, two tabs.

**Orders tab** (opens first): the orders saved by the Place order button.
- Filters: **To do** (new, confirmed, ready), **Today**, **Unpaid** (orders with a payment method that are not paid and not cancelled), **Done** (completed and cancelled), **All**. Each shows a count.
- Each order shows the number, status, customer name and phone, delivery or pickup, date and time slot, address, notes, items with line totals, delivery charge and total.
- Status buttons: **Confirm order**, then **Mark ready**, then **Mark completed**. **Cancel order** needs a second tap to confirm. Done orders can be **Reopened** or **Deleted** (second tap to confirm).
- **Payments:** each order shows its method (UPI, Cash on delivery, Pay at pickup) and an Unpaid, Paid or Refunded badge. **Mark paid** records the payment and the time, and **Mark unpaid** undoes a slip. For UPI, check your UPI app and match the order number in the payment note before marking paid. For cash, mark it paid when the money is received. Completing an order that is still unpaid needs a second tap. If a paid order is cancelled, the card shows **Refund due**, and **Mark refunded** closes it once you have refunded the customer by UPI. Orders from before payments existed show no payment details.
- **Payment reported:** when a customer taps **I've paid**, the order shows a blue **Payment reported** badge and a note ("The customer says they paid ₹490. Check your UPI app..."). The tab badge and page title count it together with new orders, and an alert appears on the next refresh. Mark paid confirms it. **Mark unpaid** also clears the report.
- **Cancelling:** after **Cancel order**, a banner offers **Tell them on WhatsApp**. It opens WhatsApp to the customer with this message already written: "Hi Asha, your order ABC123 from the shop has been cancelled. If any money was deducted, it will be refunded to you. Sorry for the trouble." The owner taps Send. The app cannot send WhatsApp messages by itself: that needs a WhatsApp Business account with an approved message template and server code, which can be added later as a paid upgrade. If the customer paid, the owner still refunds by UPI and marks the order refunded.
- **Call** and **WhatsApp** buttons for the customer. The WhatsApp message is filled in to match the order's status.
- A switch at the top turns **Accepting online orders** on or off.
- The page checks for new orders every 30 seconds while it is open and visible, and again when the owner comes back to it. A badge on the tab and in the page title shows how many are new. It cannot send phone notifications, so the WhatsApp message from the customer is still the instant alert.

**Clear old orders** (at the bottom of the Orders tab): the owner picks 30, 60, 90 or 180 days. The first tap counts the finished orders that old, and the second tap deletes them. Only completed and cancelled orders are deleted.

**Settings tab**: the owner can change the payment and delivery rules without opening Supabase: their UPI ID, whether to accept UPI, cash on delivery and pay at pickup, the cash on delivery limit, the minimum order, the delivery charge and the free delivery amount. The page warns if a combination would stop customers from ordering (for example UPI switched on without a UPI ID, and cash on delivery off). Amounts must be whole rupees. A database that has not been updated with the latest `supabase-orders.sql` shows only the amounts. `admin.html#settings` opens this tab.

**Menu tab**: change name, price, category and description, switch items between Available and Sold out, add new items, delete items (two taps to confirm).

Setup:
- Put `admin.html` and `supabase-js.umd.js` in the same folder and repo as `index.html`. The **Menu** tab also edits the photo link, badge and unit label of each item (after `supabase-menu-extras.sql` has been run). After deploying it lives at `your-site-link/admin.html`. `admin.html#menu` opens the Menu tab.
- Fill in the same `CONFIG` fields: `shopName`, `supabaseUrl`, `supabaseKey` (publishable key only).
- The owner's login is created by you in Supabase under Authentication, Users. Keep public sign-ups switched off.
- The page asks search engines not to index it, but the link is not a secret. The login is what protects the data: only the owner can read orders or change the menu, enforced by the rules in Supabase.
- If the owner forgets their password, reset it from Authentication, Users in the Supabase dashboard.

## Payments (Week 4)

After the customer taps **Place order** the page shows a payment choice, and the order is saved only when they confirm it:
- **Delivery orders:** UPI or Cash on delivery.
- **Pickup orders:** UPI or Pay at pickup.
- **UPI:** the confirmation offers three ways to pay. With a **business** UPI ID and the `upi_prefill` setting on (shown as **This is a business UPI ID** in the admin Settings), phones get a **Pay with UPI** button that opens the customer's UPI app with the UPI ID, exact total and order number filled in. With a **personal** UPI ID (the default), there is no such button, because UPI apps often restrict or fail payments that start from a web link (PhonePe shows a screenshot-payment limit notice, Amazon Pay a "technical error"). Those customers get the QR code and the UPI ID, amount and note to type, which work in every UPI app. A **QR code** (shown straight away on a computer, behind a **Show QR code** button on a phone) can be scanned by any UPI app, or screenshotted and used with Scan from gallery. And the UPI ID, amount and note are shown with Copy buttons for paying by hand. The customer then sends the order on WhatsApp with the payment screenshot. A computer cannot open UPI links, so the button only appears on phones.
- **The page cannot see whether a UPI payment went through.** Orders start as `unpaid`. After paying, the customer taps **I've paid** on the confirmation. That flags the order as **Payment reported** in the admin, with an alert like the new-order one, but it is only the customer's word. The owner checks their UPI app, matches the order number in the payment note, and taps **Mark paid**. Treat UPI orders as unconfirmed until then. Fully automatic payment confirmation needs a payment gateway.

These live in the `shop_settings` table (one row). The owner changes them in the admin page's **Settings** tab; you can also edit them in Table Editor:

| Column | What it does |
| --- | --- |
| `upi_id` | The shop's UPI ID, like `shopname@okaxis`. UPI is not offered until this is set |
| `accept_upi`, `accept_cod`, `accept_pay_at_pickup` | Switch each payment method on or off |
| `upi_prefill` | Off (default, personal UPI ID): the QR carries only the UPI ID and the customer types the amount; there is no Pay with UPI button. On (business UPI ID): the amount and order number are filled in and phones get the Pay with UPI button |
| `cod_max_total` | Largest order total allowed for cash on delivery. `0` = no limit. Default 1500 |
| `free_delivery_above` | Items total at or above this get free delivery. `0` = never free. Default 1000 |
| `min_order`, `delivery_charge` | As before |

**Back button and changing how to pay.** The phone's Back button steps back one screen at a time: confirmation, then payment choice, then cart, then closed. Pressing Back on the confirmation shows the payment screen as **Change how you pay**. It changes the same order, not a new one (`change_payment` in `supabase-orders.sql`), and only while the shop has not yet confirmed it and nothing has been paid or reported. The confirmation also has a **Change payment method** button. Once the shop confirms the order, the customer is asked to message the shop instead.

The database checks all of this again when an order is placed, so the page can't be tricked into a method or price that isn't allowed. Orders store `payment_method` (`UPI`, `COD` or `PAY_AT_PICKUP`), `payment_status` (`unpaid`, `paid` or `refunded`) and `paid_at`. Orders from before payments existed have no payment method.

To upgrade a shop that already has the Week 3 or an earlier Week 4 database, run the new `supabase-orders.sql` again. It adds the new columns and the `report_payment` function, and leaves existing orders alone.

**Personal UPI IDs and pre-filled payments.** UPI's payment link format is designed for registered merchants. When the receiving account is a personal one, banks and UPI apps can decline payments that arrive with a pre-filled amount, with errors like "technical error", "risk threshold exceeded" or a security message. That is why `upi_prefill` is off by default. For a shop that takes real UPI payments, the dependable setup is a **business UPI ID** (from PhonePe, Paytm or Google Pay for Business, or a bank merchant account), with `upi_prefill` switched on. A payment gateway (for example Razorpay) is the next step up and confirms payments automatically.

If a UPI payment fails inside the customer's UPI app (for example Amazon Pay says "technical error"), the link itself has done its job. Check these:
- **Screenshot payments have limits.** Some UPI apps stop a payment made from a screenshot (Scan from gallery) at a set amount, for example ₹2,000. On phones the confirmation shows a note about this when the total is above ₹2,000. The QR scanned live from another phone or screen, and paying to the UPI ID by hand, are not limited this way.
- **Pay ₹1 by hand first.** From someone else's phone, open any UPI app, choose pay to a UPI ID, type the shop's ID and an amount yourself. If even that fails, the UPI ID or its bank cannot receive reliably, and no link or QR will fix it: use another UPI ID.
- **Test from a different person's account.** UPI refuses a payment from an account to itself, and it often shows a vague error. Never test with the shop's own number and app.
- **Try another UPI app** (GPay, PhonePe, Paytm) and the QR code. Banks and apps sometimes have temporary problems or limits.
- **Customers see the account holder's name** in their UPI app. If it differs from the shop's name, some will hesitate. A business UPI ID or QR where the name matches the shop is more trusted.

Use a business UPI ID or QR where the shop has one. Cash on delivery for large custom orders carries a risk of refusal, which the COD limit is there to reduce.

## Privacy and keeping order data (Week 3)

Saved orders hold customers' names, phone numbers and addresses, so for every client:

1. Copy `privacy.html` next to `index.html` and edit its `CONFIG` block (shop name, WhatsApp number, retention days, last-updated date). `index.html` links to it from the note above the Place order button (`privacyUrl`).
2. Turn on the **pg_cron** extension in Supabase (Database, Extensions) and run `supabase-retention.sql` once. It deletes finished orders after 90 days and any order after 180 days, every night. If you change those numbers, change `retentionDays` and `unfinishedDays` in `privacy.html` too, so the page stays true.
3. Tell the client in plain words what is stored and for how long, and that a customer can ask them to show, correct or delete their details. The owner can delete a single order from the Done list.
4. This is not legal advice. India's Digital Personal Data Protection Act, 2023 and its 2025 rules introduce duties around privacy notices, security and erasing data that is no longer needed, with the main duties starting in 2027. Check the current position, and what applies to the client's size, with a qualified adviser.

## Security checklist (do this for every client)

**Files**
- `qrcode-generator.js` is the QR code library, version 2.0.4 (MIT licence), copied unchanged from npm (SHA-256 `79ec86f82856005b1c887905cfccfcfbec3821ca61c7fd5a952faa5f778f791c`). It sits next to `index.html`. Without it the page still works, but shows no QR code.
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
