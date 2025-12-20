-- Insert default cost factors
INSERT INTO product_margin (category, cost_factor) VALUES
-- The arbitrary cost_factors can be replaced with real
-- cost factors or the whole table can be generated from real data
    ('Electronics', 0.65),
    ('Accessories', 0.65),
    ('Other', 0.65)
ON CONFLICT (category) DO NOTHING;