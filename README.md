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
| `askDeliveryDate` | `false` hides the date field and leaves it out of the message |

**MENU**: one line per item: `id`, `name`, `category`, `price` (rupees), `description`, `available`. Items with the same `category` text are grouped together. Set `available: false` to show "Sold out".

**Colours**: the variables at the top of the `<style>` block (`--oxide`, `--gold`, `--ivory`, and so on).

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

- The cart lives in the page only, so a reload empties it.
- If `whatsapp` is a personal number, replace it before sharing a demo link publicly. Orders go to that number.
