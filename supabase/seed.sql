-- ============================================================
-- Seed données de démonstration POS
-- Remplit toutes les tables Supabase avec des exemples réalistes.
-- Exécutable dans le SQL editor Supabase ou via psql :
--   psql "$DATABASE_URL" -f supabase/seed.sql
--
-- Les id sont fixes pour rester cohérents avec le seed ObjectBox.
-- ============================================================

-- Catégories
INSERT INTO categories (id, name, parent_id, sort_order, is_active, created_at, updated_at, sync_status)
VALUES
  (1, 'Boissons', 0, 1, true,  now(), now(), 0),
  (2, 'Alimentation', 0, 2, true, now(), now(), 0),
  (3, 'Hygiène & Beauté', 0, 3, true, now(), now(), 0),
  (4, 'Électronique', 0, 4, true, now(), now(), 0),
  (5, 'Boulangerie', 0, 5, true, now(), now(), 0),
  (6, 'Entretien', 0, 6, true, now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Produits
INSERT INTO products (id, sku, name, description, category_id, price, cost_price, tax_rate, stock, low_stock_threshold, barcode, image_url, is_active, created_at, updated_at, sync_status)
VALUES
  (1,  'REF-0001', 'Coca-Cola 33cl', 'Canette 33cl, boisson gazeuse', 1, 120, 80, 0.19, 100, 20, '613000000001', null, true, now(), now(), 0),
  (2,  'REF-0002', 'Eau minérale 1,5L', 'Bouteille 1,5 litre', 1, 60, 35, 0.09, 200, 40, '613000000002', null, true, now(), now(), 0),
  (3,  'REF-0003', 'Jus d''orange 1L', 'Jus 100% orange, brique 1L', 1, 180, 120, 0.19, 45, 15, '613000000003', null, true, now(), now(), 0),
  (4,  'REF-0004', 'Huile d''olive 1L', 'Huile d''olive extra vierge', 2, 950, 700, 0.19, 60, 10, '613000000004', null, true, now(), now(), 0),
  (5,  'REF-0005', 'Riz basmati 5kg', 'Sac de riz basmati 5kg', 2, 2200, 1800, 0.19, 35, 8, '613000000005', null, true, now(), now(), 0),
  (6,  'REF-0006', 'Couscous 1kg', 'Couscous moyen 1kg', 2, 260, 190, 0.19, 80, 20, '613000000006', null, true, now(), now(), 0),
  (7,  'REF-0007', 'Pâtes spaghetti 500g', 'Paquet de spaghetti 500g', 2, 150, 100, 0.19, 120, 25, '613000000007', null, true, now(), now(), 0),
  (8,  'REF-0008', 'Shampooing 500ml', 'Shampooing cheveux normaux', 3, 450, 300, 0.19, 40, 10, '613000000008', null, true, now(), now(), 0),
  (9,  'REF-0009', 'Dentifrice 100ml', 'Dentifrice blancheur', 3, 220, 140, 0.19, 6, 15, '613000000009', null, true, now(), now(), 0),
  (10, 'REF-0010', 'Gel douche 250ml', 'Gel douche hydratant', 3, 300, 200, 0.19, 0, 12, '613000000010', null, true, now(), now(), 0),
  (11, 'REF-0011', 'Câble USB-C 1m', 'Câble de charge rapide USB-C', 4, 350, 150, 0.19, 90, 20, '613000000011', null, true, now(), now(), 0),
  (12, 'REF-0012', 'Chargeur 25W', 'Chargeur murale 25W USB-C', 4, 900, 500, 0.19, 30, 8, '613000000012', null, true, now(), now(), 0),
  (13, 'REF-0013', 'Écouteurs Bluetooth', 'Écouteurs sans fil avec étui', 4, 2500, 1500, 0.19, 15, 5, '613000000013', null, true, now(), now(), 0),
  (14, 'REF-0014', 'Pain complet', 'Pain de campagne complet', 5, 25, 12, 0.0, 0, 30, '613000000014', null, true, now(), now(), 0),
  (15, 'REF-0015', 'Baguette', 'Baguette traditionnelle', 5, 15, 7, 0.0, 150, 40, '613000000015', null, true, now(), now(), 0),
  (16, 'REF-0016', 'Lessive 2kg', 'Lessive poudre 2kg', 6, 850, 600, 0.19, 25, 8, '613000000016', null, true, now(), now(), 0),
  (17, 'REF-0017', 'Produit vaisselle 750ml', 'Liquide vaisselle citron', 6, 180, 110, 0.19, 55, 15, '613000000017', null, true, now(), now(), 0),
  (18, 'REF-0018', 'Sac poubelle 50L', 'Rouleau 50L (lot de 20)', 6, 120, 70, 0.19, 130, 25, '613000000018', null, true, now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Clients
INSERT INTO customers (id, name, phone, email, address, company, tax_id, notes, created_at, updated_at, sync_status)
VALUES
  (1, 'Kamel Benali', '0550 12 34 56', 'kamel.benali@example.dz', 'Cité 200 Logts, Alger', 'SARL Benali Import', '099912345678', null, now(), now(), 0),
  (2, 'Fatima Zohra', '0661 98 76 54', 'fatima.zohra@example.dz', 'Rue Didouche Mourad, Alger', null, null, null, now(), now(), 0),
  (3, 'Restaurant Le Gourmet', '023 45 67 89', 'contact@legourmet.dz', 'Zone d''activité, Oran', 'EURL Le Gourmet', '099876543210', 'Client professionnel, facturation 30 jours', now(), now(), 0),
  (4, 'Amina Cherif', '0770 22 33 44', null, 'Boulevard Zighout Youcef, Constantine', null, null, null, now(), now(), 0),
  (5, 'Épicerie du Centre', '0555 11 22 33', 'epicerie.centre@example.dz', null, 'SARL Épicerie du Centre', '099900112233', 'Revente en gros', now(), now(), 0),
  (6, 'Mohamed Larbi', '0666 44 55 66', null, 'Cité 5 Juillet, Blida', null, null, null, now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Ventes
INSERT INTO sales (id, sale_number, customer_id, cashier_id, payment_method, status, discount_total, total, created_at, updated_at, sync_status)
VALUES
  (1, '000001', 1, 0, 0, 1, 0,    856.60, now() - interval '10 days', now() - interval '10 days', 0),
  (2, '000002', 3, 0, 1, 1, 0,   8927.50, now() - interval '8 days',  now() - interval '8 days',  0),
  (3, '000003', 2, 0, 2, 1, 0,   1725.50, now() - interval '6 days',  now() - interval '6 days',  0),
  (4, '000004', 0, 0, 0, 1, 0,   2046.30, now() - interval '4 days',  now() - interval '4 days',  0),
  (5, '000005', 5, 0, 3, 1, 100, 15370.00, now() - interval '3 days', now() - interval '3 days', 0),
  (6, '000006', 4, 0, 0, 1, 0,   2153.90, now() - interval '2 days', now() - interval '2 days', 0),
  (7, '000007', 6, 0, 1, 1, 0,   5628.40, now() - interval '1 day',  now() - interval '1 day',  0),
  (8, '000008', 0, 0, 0, 0, 0,    345.60, now() - interval '5 hours', now() - interval '5 hours', 0)
ON CONFLICT (id) DO UPDATE SET sale_number = EXCLUDED.sale_number;

-- Lignes de vente
INSERT INTO sale_items (sale_id, product_id, product_name, sku, unit_price, cost_price, tax_rate, quantity, discount)
VALUES
  (1, 1, 'Coca-Cola 33cl', 'REF-0001', 120, 80, 0.19, 2, 0),
  (1, 2, 'Eau minérale 1,5L', 'REF-0002', 60, 35, 0.09, 4, 0),
  (1, 6, 'Couscous 1kg', 'REF-0006', 260, 190, 0.19, 1, 0),
  (2, 5, 'Riz basmati 5kg', 'REF-0005', 2200, 1800, 0.19, 2, 0),
  (2, 4, 'Huile d''olive 1L', 'REF-0004', 950, 700, 0.19, 3, 0),
  (2, 15, 'Baguette', 'REF-0015', 15, 7, 0.0, 20, 0),
  (3, 7, 'Pâtes spaghetti 500g', 'REF-0007', 150, 100, 0.19, 5, 0),
  (3, 11, 'Câble USB-C 1m', 'REF-0011', 350, 150, 0.19, 2, 0),
  (4, 2, 'Eau minérale 1,5L', 'REF-0002', 60, 35, 0.09, 10, 0),
  (4, 1, 'Coca-Cola 33cl', 'REF-0001', 120, 80, 0.19, 3, 0),
  (4, 8, 'Shampooing 500ml', 'REF-0008', 450, 300, 0.19, 1, 0),
  (4, 17, 'Produit vaisselle 750ml', 'REF-0017', 180, 110, 0.19, 2, 0),
  (5, 12, 'Chargeur 25W', 'REF-0012', 900, 500, 0.19, 5, 0),
  (5, 13, 'Écouteurs Bluetooth', 'REF-0013', 2500, 1500, 0.19, 2, 0),
  (5, 11, 'Câble USB-C 1m', 'REF-0011', 350, 150, 0.19, 10, 0),
  (6, 9, 'Dentifrice 100ml', 'REF-0009', 220, 140, 0.19, 3, 0),
  (6, 10, 'Gel douche 250ml', 'REF-0010', 300, 200, 0.19, 1, 0),
  (6, 16, 'Lessive 2kg', 'REF-0016', 850, 600, 0.19, 1, 0),
  (7, 13, 'Écouteurs Bluetooth', 'REF-0013', 2500, 1500, 0.19, 1, 0),
  (7, 4, 'Huile d''olive 1L', 'REF-0004', 950, 700, 0.19, 2, 0),
  (7, 2, 'Eau minérale 1,5L', 'REF-0002', 60, 35, 0.09, 6, 0),
  (8, 15, 'Baguette', 'REF-0015', 15, 7, 0.0, 4, 0),
  (8, 1, 'Coca-Cola 33cl', 'REF-0001', 120, 80, 0.19, 2, 0);

-- Factures
-- Note : sale_id est NOT NULL en base ; la valeur 0 signifie "aucune vente"
-- (l'application la convertit en null côté domaine).
INSERT INTO invoices (id, invoice_number, sale_id, customer_id, status, discount_total, company_name, company_address, company_tax_id, due_date, created_at, updated_at, sync_status)
VALUES
  (1, '000001', 2, 3, 2, 0, 'POS Module', 'Alger, Algérie', '099900000000', null, now() - interval '8 days', now() - interval '8 days', 0),
  (2, '000002', 0, 3, 1, 50, 'POS Module', 'Alger, Algérie', '099900000000', now() + interval '20 days', now() - interval '4 days', now() - interval '4 days', 0),
  (3, '000003', 0, 5, 3, 0, 'POS Module', 'Alger, Algérie', '099900000000', now() - interval '5 days', now() - interval '35 days', now() - interval '35 days', 0),
  (4, '000004', 0, 1, 2, 0, 'POS Module', 'Alger, Algérie', '099900000000', null, now() - interval '1 day', now() - interval '1 day', 0),
  (5, '000005', 8, 0, 0, 0, 'POS Module', 'Alger, Algérie', '099900000000', null, now() - interval '3 hours', now() - interval '3 hours', 0)
ON CONFLICT (id) DO UPDATE SET invoice_number = EXCLUDED.invoice_number;

-- Lignes de facture
INSERT INTO invoice_items (invoice_id, product_id, description, unit_price, quantity, tax_rate, discount)
VALUES
  (1, 5, 'Riz basmati 5kg', 2200, 2, 0.19, 0),
  (1, 4, 'Huile d''olive 1L', 950, 3, 0.19, 0),
  (1, 15, 'Baguette', 15, 20, 0.0, 0),
  (2, 12, 'Chargeur 25W', 900, 5, 0.19, 0),
  (2, 13, 'Écouteurs Bluetooth', 2500, 2, 0.19, 0),
  (2, 11, 'Câble USB-C 1m', 350, 10, 0.19, 0),
  (3, 6, 'Couscous 1kg', 260, 20, 0.19, 0),
  (3, 2, 'Eau minérale 1,5L', 60, 24, 0.09, 0),
  (4, 9, 'Dentifrice 100ml', 220, 3, 0.19, 0),
  (4, 16, 'Lessive 2kg', 850, 1, 0.19, 0),
  (4, 8, 'Shampooing 500ml', 450, 1, 0.19, 0),
  (5, 15, 'Baguette', 15, 4, 0.0, 0),
  (5, 1, 'Coca-Cola 33cl', 120, 2, 0.19, 0);

-- Paiements
INSERT INTO payments (id, amount, method, sale_id, invoice_id, reference, paid_at, sync_status)
VALUES
  (1, 856.60, 0, 1, 0, 'TICKET-000001', now() - interval '10 days', 0),
  (2, 8927.50, 1, 2, 0, 'TICKET-000002', now() - interval '8 days', 0),
  (3, 1725.50, 2, 3, 0, 'TICKET-000003', now() - interval '6 days', 0),
  (4, 2046.30, 0, 4, 0, 'TICKET-000004', now() - interval '4 days', 0),
  (5, 15370.00, 3, 5, 0, 'TICKET-000005', now() - interval '3 days', 0),
  (6, 2153.90, 0, 6, 0, 'TICKET-000006', now() - interval '2 days', 0),
  (7, 5628.40, 1, 7, 0, 'TICKET-000007', now() - interval '1 day', 0),
  (8, 7757.60, 0, 0, 3, 'REG-000003', now() - interval '5 days', 0)
ON CONFLICT (id) DO UPDATE SET reference = EXCLUDED.reference;

-- Réinitialiser les séquences pour que les prochains enregistrements
-- ne rentrent pas en collision avec les id seedés.
SELECT setval(pg_get_serial_sequence('categories', 'id'), COALESCE((SELECT MAX(id) FROM categories), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('products', 'id'), COALESCE((SELECT MAX(id) FROM products), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('customers', 'id'), COALESCE((SELECT MAX(id) FROM customers), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('sales', 'id'), COALESCE((SELECT MAX(id) FROM sales), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('invoices', 'id'), COALESCE((SELECT MAX(id) FROM invoices), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('payments', 'id'), COALESCE((SELECT MAX(id) FROM payments), 0) + 1, false);
