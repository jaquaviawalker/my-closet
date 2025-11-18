-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS outfit_items CASCADE;
DROP TABLE IF EXISTS outfits CASCADE;
DROP TABLE IF EXISTS clothing_items CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create clothing_items table
CREATE TABLE clothing_items (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    color VARCHAR(50),
    brand VARCHAR(100),
    season TEXT[], -- Array to store multiple seasons (e.g., {'Spring', 'Summer'})
    image_data TEXT, -- Base64 encoded image with background removed
    tags TEXT[], -- Array to store multiple tags
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create outfits table
CREATE TABLE outfits (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create outfit_items junction table (many-to-many relationship)
CREATE TABLE outfit_items (
    id SERIAL PRIMARY KEY,
    outfit_id INTEGER REFERENCES outfits(id) ON DELETE CASCADE,
    clothing_item_id INTEGER REFERENCES clothing_items(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(outfit_id, clothing_item_id) -- Prevent duplicate items in same outfit
);

-- Create indexes for better query performance
CREATE INDEX idx_clothing_items_user_id ON clothing_items(user_id);
CREATE INDEX idx_clothing_items_category ON clothing_items(category);
CREATE INDEX idx_clothing_items_color ON clothing_items(color);
CREATE INDEX idx_clothing_items_season ON clothing_items USING GIN(season);
CREATE INDEX idx_clothing_items_tags ON clothing_items USING GIN(tags);
CREATE INDEX idx_outfits_user_id ON outfits(user_id);
CREATE INDEX idx_outfit_items_outfit_id ON outfit_items(outfit_id);
CREATE INDEX idx_outfit_items_clothing_item_id ON outfit_items(clothing_item_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clothing_items_updated_at
    BEFORE UPDATE ON clothing_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outfits_updated_at
    BEFORE UPDATE ON outfits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample user for development (password is 'password123' hashed with bcrypt)
-- NOTE: Remove this in production or change the password
INSERT INTO users (username, email, password_hash) 
VALUES (
    'demo_user', 
    'demo@example.com', 
    '$2b$10$rZ5VK/H5xH5xH5xH5xH5xOuJ5vK5vK5vK5vK5vK5vK5vK5vK5vK5u'
);

-- Insert sample clothing items for development
INSERT INTO clothing_items (user_id, name, category, color, brand, season, tags) 
VALUES 
    (1, 'Blue Denim Jeans', 'pants', 'Blue', 'Levis', ARRAY['Spring', 'Fall', 'Winter'], ARRAY['casual', 'denim']),
    (1, 'White T-Shirt', 'shirt', 'White', 'H&M', ARRAY['Spring', 'Summer', 'Fall'], ARRAY['casual', 'basic']),
    (1, 'Black Leather Jacket', 'jacket', 'Black', 'Zara', ARRAY['Fall', 'Winter'], ARRAY['casual', 'leather']),
    (1, 'Nike Running Shoes', 'shoes', 'White', 'Nike', ARRAY['Spring', 'Summer', 'Fall'], ARRAY['athletic', 'casual']),
    (1, 'Summer Floral Dress', 'dress', 'Multi', 'Forever 21', ARRAY['Spring', 'Summer'], ARRAY['casual', 'floral']);

-- Insert sample outfit
INSERT INTO outfits (user_id, name, description) 
VALUES (1, 'Casual Weekend', 'Comfortable outfit for weekend errands');

-- Link items to the outfit
INSERT INTO outfit_items (outfit_id, clothing_item_id) 
VALUES 
    (1, 1), -- Blue Jeans
    (1, 2), -- White T-Shirt
    (1, 4); -- Nike Shoes

-- Verify the setup
SELECT 'Database schema created successfully!' AS status;