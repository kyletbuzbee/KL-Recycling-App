const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;
const JWT_SECRET = 'kl-recycling-secret-key-2024';

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// File upload configuration
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Invalid file type'));
  }
});

// Create uploads directory if it doesn't exist
if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads');
}

// In-memory data stores (for demo purposes)
let users = [];
let quotes = [];
let schedules = [];
let pushTokens = [];
let uploads = [];
let userActivities = [];

// Helper functions
const generateId = () => Date.now().toString() + Math.random().toString(36).substr(2, 9);

// Auth middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};

// Auth endpoints
app.post('/api/auth/register', async (req, res) => {
  const { name, email, password, phone, company } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }

  const existingUser = users.find(u => u.email === email);
  if (existingUser) {
    return res.status(409).json({ error: 'User already exists' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = {
      id: generateId(),
      name,
      email,
      password: hashedPassword,
      phone: phone || '',
      company: company || '',
      createdAt: new Date().toISOString(),
      profileImage: null,
      pushToken: null,
      notificationSettings: {
        quotes: true,
        schedules: true,
        promotions: false
      }
    };

    users.push(user);

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET);
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: { ...user, password: undefined }
    });
  } catch (error) {
    res.status(500).json({ error: 'Registration failed' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  const user = users.find(u => u.email === email);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  try {
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET);
    res.json({
      success: true,
      token,
      user: { ...user, password: undefined }
    });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

app.get('/api/auth/profile', authenticateToken, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });

  res.json({ user: { ...user, password: undefined } });
});

app.put('/api/auth/profile', authenticateToken, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });

  const { name, phone, company, notificationSettings } = req.body;
  user.name = name || user.name;
  user.phone = phone || user.phone;
  user.company = company || user.company;
  user.notificationSettings = { ...user.notificationSettings, ...notificationSettings };

  res.json({
    success: true,
    user: { ...user, password: undefined }
  });
});

// Push notifications
app.post('/api/notifications/register', authenticateToken, (req, res) => {
  const { pushToken } = req.body;
  if (!pushToken) return res.status(400).json({ error: 'Push token required' });

  const user = users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });

  user.pushToken = pushToken;
  const existingToken = pushTokens.find(t => t.userId === req.user.id);
  if (existingToken) {
    existingToken.pushToken = pushToken;
  } else {
    pushTokens.push({ userId: req.user.id, pushToken, platform: req.body.platform || 'ios' });
  }

  res.json({ success: true, message: 'Push token registered' });
});

// File upload
app.post('/api/uploads/photos', authenticateToken, upload.single('photo'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const uploadEntry = {
    id: generateId(),
    userId: req.user.id,
    filename: req.file.filename,
    originalName: req.file.originalname,
    mimetype: req.file.mimetype,
    size: req.file.size,
    uploadDate: new Date().toISOString(),
    purpose: req.body.purpose || 'material_sample' // Could be 'quote', 'schedule', 'material_sample'
  };

  uploads.push(uploadEntry);

  res.json({
    success: true,
    upload: {
      id: uploadEntry.id,
      url: `/uploads/${req.file.filename}`,
      purpose: uploadEntry.purpose
    }
  });
});

// Serve uploaded files
app.use('/uploads', express.static('uploads'));

// Services and materials data
app.get('/api/services/details', (req, res) => {
  const services = [
    {
      id: 'roll-off',
      name: 'Roll-Off Container Service',
      description: 'Convenient drop-off and pickup services for construction and industrial needs. Multiple sizes available.',
      details: '15, 20, 30, and 40-yard containers. Same-day delivery at no extra charge.',
      pricing: 'Starting at $275/month',
      features: ['Multiple sizes', 'Same-day delivery', 'Flexible terms', 'REMA certified'],
      icon: 'truck'
    },
    {
      id: 'mobile-crushing',
      name: 'Mobile Concrete Crushing',
      description: 'On-site crushing services for concrete and asphalt recycling.',
      details: 'Environmentally friendly and cost-effective. Turn waste into reusable aggregate.',
      pricing: 'Custom quotes available',
      features: ['On-site service', 'Multiple equipment', 'Professional crew', 'Sustainable practice'],
      icon: 'crane'
    },
    {
      id: 'industrial-demolition',
      name: 'Industrial Demolition',
      description: 'Complete demolition and cleanup services with REMA certification.',
      details: 'Expert demolition services for industrial and commercial buildings.',
      pricing: 'Project-based pricing',
      features: ['REMA certified', 'Full cleanup', 'Material recovery', 'Insurance qualified'],
      icon: 'hammer'
    },
    {
      id: 'public-services',
      name: 'Public Service Support',
      description: 'Partnerships with local governments and public service organizations.',
      details: 'Support for municipal projects and community initiatives.',
      pricing: 'Municipal rates available',
      features: ['Public partnerships', 'Volume discounts', 'Flexible scheduling', 'Community support'],
      icon: 'building'
    }
  ];
  res.json({ services });
});

app.get('/api/materials/guide', (req, res) => {
  const materials = [
    {
      id: 'ferrous',
      name: 'Ferrous Metals',
      category: 'Ferrous (60% of volume)',
      description: 'Magnetic metals with iron content including steel, iron, and metal alloys used in construction and manufacturing.',
      examples: ['Steel beams', 'Iron pipes', 'Metal cans', 'Scrap metal'],
      pricing: 'Market driven, call for current rates',
      tips: 'Remove non-ferrous attachments before delivery'
    },
    {
      id: 'non-ferrous',
      name: 'Non-Ferrous Metals',
      category: 'Non-Ferrous (30% of volume)',
      description: 'Valuable metals without iron content including copper, aluminum, brass, and stainless steel for higher market value.',
      examples: ['Copper wire', 'Aluminum cans', 'Brass fixtures', 'Stainless steel'],
      pricing: 'Premium rates, call for quotes',
      tips: 'Separate different non-ferrous metals for best pricing'
    },
    {
      id: 'precious',
      name: 'Precious Metals',
      category: 'Precious (10% of volume)',
      description: 'High-value specialty commodities including gold, silver, platinum, and other rare metals from electronics and industry.',
      examples: ['Gold jewelry', 'Silver coins', 'Platinum catalysts', 'Palladium'],
      pricing: 'Premium commodities, refined pricing',
      tips: 'Professional assessment required'
    }
  ];
  res.json({ materials });
});

// Impact calculator
app.post('/api/impact/calculate', (req, res) => {
  const { materialType, quantity, unit } = req.body;

  // Simplified calculations (real implementation would use actual data)
  const impactFactors = {
    ferrous: { co2Prevented: 1.2, trees: 0.8 },
    nonferrous: { co2Prevented: 2.5, trees: 2.1 },
    precious: { co2Prevented: 3.8, trees: 3.2 }
  };

  const factor = impactFactors[materialType] || impactFactors.ferrous;
  const totalCO2Prevented = quantity * (unit === 'kg' ? factor.co2Prevented : factor.co2Prevented * 2.2);
  const treesEquivalent = quantity * (unit === 'kg' ? factor.trees : factor.trees * 2.2);

  res.json({
    success: true,
    impact: {
      co2Prevented: Math.round(totalCO2Prevented * 10) / 10,
      treesEquivalent: Math.round(treesEquivalent * 10) / 10,
      materialType: materialType,
      quantity: quantity,
      unit: unit,
      explanation: `Recycling this amount prevents ${totalCO2Prevented.toFixed(1)} kg of CO2 emissions and saves the equivalent of ${treesEquivalent.toFixed(1)} mature trees.`
    }
  });
});

// User history/activities
app.get('/api/users/history', authenticateToken, (req, res) => {
  const userActivities = [
    ...quotes.filter(q => q.userId === req.user.id).map(q => ({ ...q, type: 'quote' })),
    ...schedules.filter(s => s.userId === req.user.id).map(s => ({ ...s, type: 'schedule' }))
  ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  res.json({ activities: userActivities.slice(0, 10) }); // Last 10 activities
});

// Quote endpoint (enhanced)
app.post('/api/quote', async (req, res) => {
  const { name, email, phone, company, material, quantity, notes, photos = [] } = req.body;

  let userId = null;
  let token = req.headers['authorization'];
  if (token && token.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(token.split(' ')[1], JWT_SECRET);
      userId = decoded.id;
    } catch (e) {
      // Invalid token, proceed without user association
    }
  }

  const quote = {
    id: generateId(),
    userId,
    name,
    email,
    phone,
    company,
    material,
    quantity,
    notes,
    photos,
    status: 'pending',
    createdAt: new Date().toISOString()
  };

  quotes.push(quote);

  // Simulate async processing
  setTimeout(() => {
    console.log('Quote Request:', quote);

    // Mark as processed after delay
    setTimeout(() => {
      quote.status = 'processed';
      quote.quoteId = generateId();
      quote.quoteAmount = `$${(Math.random() * 500 + 100).toFixed(2)}`;
    }, 5000);

  }, 100);

  res.json({
    success: true,
    message: 'Quote request received successfully. We will contact you within 24 hours.',
    id: quote.id
  });
});

// Schedule endpoint (enhanced)
app.post('/api/schedule', async (req, res) => {
  const { name, email, phone, company, materialType, pickupAddress, pickupDate, notes, photos = [] } = req.body;

  let userId = null;
  let token = req.headers['authorization'];
  if (token && token.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(token.split(' ')[1], JWT_SECRET);
      userId = decoded.id;
    } catch (e) {
      // Invalid token, proceed without user association
    }
  }

  const schedule = {
    id: generateId(),
    userId,
    name,
    email,
    phone,
    company,
    materialType,
    pickupAddress,
    pickupDate,
    notes,
    photos,
    status: 'scheduled',
    createdAt: new Date().toISOString()
  };

  schedules.push(schedule);

  console.log('Schedule Request:', schedule);

  // Simulate confirmation
  setTimeout(() => {
    schedule.status = 'confirmed';
    schedule.confirmationId = generateId();
    schedule.confirmedBy = 'System';
    schedule.confirmedAt = new Date().toISOString();
  }, 2000);

  res.json({
    success: true,
    message: 'Pickup scheduled successfully. Our team will contact you to confirm.',
    id: schedule.id
  });
});

// Locations data
app.get('/api/locations', (req, res) => {
  const locations = [
    {
      id: 'tyler',
      name: 'Tyler Headquarters',
      address: '4134 Chandler Hwy, Tyler, TX 75702',
      phone: '(903) 592-6299',
      hours: 'Mon-Fri: 6AM-5PM',
      services: ['All services']
    },
    {
      id: 'mineola',
      name: 'Mineola Facility',
      address: '2590 Highway 80 West, Mineola, TX 75773',
      phone: '(903) 569-6231',
      hours: 'Mon-Fri: 7AM-4PM',
      services: ['Processing', 'Scaling']
    },
    {
      id: 'palestine',
      name: 'Palestine Facility',
      address: '4340 State Highway 19, Palestine, TX 75801',
      phone: '(903) 723-0171',
      hours: 'Mon-Fri: 7AM-4PM',
      services: ['Processing', 'Demolition']
    },
    {
      id: 'nacogdoches',
      name: 'Nacogdoches Facility',
      address: '2508 Woden Road, Nacogdoches, TX 75961',
      phone: '(936) 560-2244',
      hours: 'Mon-Fri: 7AM-4PM',
      services: ['Processing', 'Mobile Crushing']
    },
    {
      id: 'great-bend',
      name: 'Great Bend Facility',
      address: '700 Frey Street, Great Bend, KS 67530',
      phone: '(620) 792-5956',
      hours: 'Mon-Fri: 8AM-5PM',
      services: ['All services']
    }
  ];
  res.json({ locations });
});

// Clean up - simulate data persistence
process.on('SIGINT', () => {
  console.log('Server shutting down...');
  // In production, save to actual database
  process.exit(0);
});

// Start server
app.listen(port, () => {
  console.log(`KL-Recycling API server running on port ${port}`);
  console.log(`Server features: Auth, File uploads, Push notifications, Impact calculator`);
});

module.exports = app;
