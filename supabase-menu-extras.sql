-- =====================================================================
-- MENU EXTRAS: PHOTO, BADGE AND UNIT LABEL FOR EVERY MENU ITEM
--
-- Run this ONCE in the Supabase SQL Editor. It is safe to run again.
-- It adds three optional columns to menu_items:
--   image_url   a link to the item's photo. Must start with https://
--               (or images/ for a file in your site's images folder).
--   badge       a small tag on the photo, for example Bestseller (30 letters at most)
--   unit_label  a small line under the name, for example BOX OF 4 (40 letters at most)
--
-- Until you run it, the site and the admin page still work: they just show
-- drawings and no badges, and the admin hides those three fields.
-- =====================================================================

alter table menu_items
  add column if not exists image_url text,
  add column if not exists badge text,
  add column if not exists unit_label text;

alter table menu_items drop constraint if exists image_url_format;
alter table menu_items add constraint image_url_format
  check (image_url is null or (char_length(image_url) <= 500 and image_url ~ '^(https://|images/)[^[:space:]"''<>]+$'));

alter table menu_items drop constraint if exists badge_length;
alter table menu_items add constraint badge_length
  check (badge is null or char_length(badge) <= 30);

alter table menu_items drop constraint if exists unit_label_length;
alter table menu_items add constraint unit_label_length
  check (unit_label is null or char_length(unit_label) <= 40);


-- ---------------------------------------------------------------------
-- OPTIONAL: demo labels for the Namma Fresh Bakes demo menu.
-- Remove the two dashes at the start of the lines below to use them,
-- or just type the values in the admin page's Menu tab instead.
-- ---------------------------------------------------------------------
-- update menu_items set unit_label = '1 KG',        badge = 'Celebrations'    where name like 'Custom Photo-Theme Cake%';
-- update menu_items set unit_label = '1 KG'                                    where name like 'Black Forest%';
-- update menu_items set unit_label = '1 KG',        badge = 'Eggless'         where name like 'Eggless Chocolate Truffle%';
-- update menu_items set unit_label = '1 KG',        badge = 'Seasonal'        where name like 'Eggless Mango%';
-- update menu_items set unit_label = '500 G LOAF',  badge = 'Weekend special' where name like 'Sourdough%';
-- update menu_items set unit_label = '400 G LOAF'                              where name like 'Multigrain%';
-- update menu_items set unit_label = 'BOX OF 12',   badge = 'Bestseller'      where name like 'Butter Cookies%';
-- update menu_items set unit_label = 'BOX OF 6'                                where name like 'Choco-Chip%';
-- update menu_items set unit_label = 'BOX OF 6',    badge = 'Millet'          where name like 'Ragi Chocolate%';
-- update menu_items set unit_label = 'BOX OF 4'                                where name like 'Jowar Banana%';
