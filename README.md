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
| `colors` | `main`, `accent` and `background` brand colours (keep the background light) |

Customers choose **Delivery** or **Pickup**. The address field only appears, and is only required, for Delivery. The date and time labels change to match.

**MENU**: one line per item: `id`, `name`, `category`, `price` (rupees), `description`, `available`. Items with the same `category` text are grouped together. Set `available: false` to show "Sold out".

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
