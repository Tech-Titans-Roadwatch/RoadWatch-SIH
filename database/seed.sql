-- Sample data for development / demo testing
-- Run after schema.sql:
--   psql -U postgres -d roadwatch -f database/seed.sql

-- Sample data for development / demo testing
-- Run after schema.sql:
--   psql -U postgres -d roadwatch -f database/seed.sql

INSERT INTO complaints (
    image_url, 
    latitude, 
    longitude, 
    place_name, 
    description,
    severity, 
    ai_confidence, 
    detections_count, 
    ai_summary,
    status, 
    assigned_department
)
VALUES 
(
    '/uploads/sample1.jpg', 
    28.6139, 
    77.2090, 
    'Connaught Place, New Delhi', 
    'Large pothole near main junction causing traffic slowdown.',
    'High', 
    0.87, 
    3, 
    'Detected 3 pothole region(s). Largest covers 42.1% of frame, avg confidence 0.87.',
    'Reported', 
    'Unassigned'
),
(
    '/uploads/sample2.jpg', 
    28.6200, 
    77.2150, 
    'Rajouri Garden, New Delhi', 
    'Pothole after rain, road partially flooded.',
    'Medium', 
    0.65, 
    1, 
    'Detected 1 pothole region(s). Largest covers 18.5% of frame, avg confidence 0.65.',
    'Reported', 
    'Unassigned'
),
(
    '/uploads/sample3.jpg', 
    28.6950, 
    77.2010, 
    'Sector 62, Noida', 
    'Small crack developing near footpath.',
    'Low', 
    0.40, 
    1, 
    'Detected 1 pothole region(s). Largest covers 5.2% of frame, avg confidence 0.40.',
    'Reported', 
    'Unassigned'
);