import React, { useState, useEffect, useContext, createContext } from 'react';
import {
  StyleSheet, Text, View, ScrollView, TouchableOpacity, TextInput, Alert, Platform,
  Modal, Image, Dimensions, ActivityIndicator, FlatList, Switch, RefreshControl
} from 'react-native';
import { NavigationContainer, useNavigation } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import { launchImageLibrary } from 'react-native-image-picker';
import { Ionicons, MaterialIcons, AntDesign, Entypo, Feather } from '@expo/vector-icons';

// Initialize Firebase
import './firebase';

// API Configuration
// For physical devices, replace 'http://192.168.1.74:3000' with your computer's IP address
const API_BASE_URL = Platform.OS === 'ios' ? 'http://192.168.1.74:3000' : 'http://10.0.2.2:3000';

// Colors (updated to royal blue theme)
const COLORS = {
  primary: '#4169E1', // Royal blue
  primaryLight: '#5B7CE7',
  primaryDark: '#2D50B7',
  secondary: '#4a4a4a', // Charcoal gray
  accent: '#f97316', // Orange accent
  background: '#ffffff',
  surface: '#f8f9fa',
  text: '#333333',
  textSecondary: '#6c757d',
  border: '#dee2e6',
  success: '#28a745',
  warning: '#ffc107',
  error: '#dc3545',
  card: '#ffffff',
};

// Global Auth Context
const AuthContext = createContext();

const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkAuthState();
  }, []);

  const checkAuthState = async () => {
    try {
      const storedToken = await AsyncStorage.getItem('authToken');
      const storedUser = await AsyncStorage.getItem('userData');

      if (storedToken && storedUser) {
        setToken(storedToken);
        setUser(JSON.parse(storedUser));
        axios.defaults.headers.common['Authorization'] = `Bearer ${storedToken}`;
      }
    } catch (error) {
      console.error('Auth check error:', error);
    } finally {
      setLoading(false);
    }
  };

  const login = async (email, password) => {
    try {
      const response = await axios.post(`${API_BASE_URL}/api/auth/login`, { email, password });
      const { token: newToken, user: userData } = response.data;

      setToken(newToken);
      setUser(userData);
      axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`;

      await AsyncStorage.setItem('authToken', newToken);
      await AsyncStorage.setItem('userData', JSON.stringify(userData));

      return { success: true };
    } catch (error) {
      return { success: false, error: error.response?.data?.error || 'Login failed' };
    }
  };

  const register = async (userData) => {
    try {
      const response = await axios.post(`${API_BASE_URL}/api/auth/register`, userData);
      const { token: newToken, user: newUser } = response.data;

      setToken(newToken);
      setUser(newUser);
      axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`;

      await AsyncStorage.setItem('authToken', newToken);
      await AsyncStorage.setItem('userData', JSON.stringify(newUser));

      return { success: true };
    } catch (error) {
      return { success: false, error: error.response?.data?.error || 'Registration failed' };
    }
  };

  const logout = async () => {
    setUser(null);
    setToken(null);
    delete axios.defaults.headers.common['Authorization'];
    await AsyncStorage.removeItem('authToken');
    await AsyncStorage.removeItem('userData');
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, register, logout, checkAuthState }}>
      {children}
    </AuthContext.Provider>
  );
};

const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    backgroundColor: COLORS.primary,
    padding: 20,
    paddingTop: 50,
  },
  headerText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: COLORS.background,
    textAlign: 'center',
    fontFamily: 'Inter-Bold',
  },
  section: {
    padding: 20,
  },
  sectionHeader: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 15,
    color: COLORS.text,
    fontFamily: 'Inter-Bold',
  },
  input: {
    borderWidth: 1,
    borderColor: COLORS.border,
    backgroundColor: COLORS.surface,
    padding: 15,
    marginBottom: 15,
    borderRadius: 8,
    fontSize: 16,
    fontFamily: 'Inter-Regular',
  },
  button: {
    backgroundColor: COLORS.primary,
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginVertical: 5,
  },
  buttonText: {
    color: COLORS.background,
    fontWeight: 'bold',
    fontSize: 16,
    fontFamily: 'Inter-Bold',
  },
  buttonSecondary: {
    backgroundColor: COLORS.background,
    borderWidth: 2,
    borderColor: COLORS.primary,
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginVertical: 5,
  },
  buttonSecondaryText: {
    color: COLORS.primary,
    fontWeight: 'bold',
    fontSize: 16,
    fontFamily: 'Inter-Bold',
  },
  card: {
    backgroundColor: COLORS.card,
    padding: 20,
    marginVertical: 10,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
    color: COLORS.text,
    fontFamily: 'Inter-Bold',
  },
  cardText: {
    fontSize: 14,
    color: COLORS.textSecondary,
    lineHeight: 20,
    fontFamily: 'Inter-Regular',
  },
  hero: {
    height: 300,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.primary,
    paddingHorizontal: 20,
  },
  heroTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: COLORS.background,
    textAlign: 'center',
    marginBottom: 10,
    fontFamily: 'Inter-Bold',
  },
  heroSubtitle: {
    fontSize: 16,
    color: COLORS.background,
    textAlign: 'center',
    opacity: 0.9,
    fontFamily: 'Inter-Regular',
  },
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.background,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modal: {
    backgroundColor: COLORS.background,
    borderRadius: 12,
    padding: 20,
    width: '90%',
    maxHeight: '80%',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
    fontFamily: 'Inter-Bold',
  },
  tabBar: {
    backgroundColor: COLORS.primaryDark,
  },
  tabBarLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
  },
  badge: {
    backgroundColor: COLORS.accent,
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    minWidth: 20,
    alignItems: 'center',
  },
  badgeText: {
    color: COLORS.background,
    fontSize: 12,
    fontWeight: 'bold',
    fontFamily: 'Inter-Bold',
  },
});

// Navigation
const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

// Auth Screens
const LoginScreen = ({ navigation }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Please fill in all fields');
      return;
    }

    setLoading(true);
    const result = await login(email, password);
    setLoading(false);

    if (result.success) {
      navigation.replace('MainTabs');
    } else {
      Alert.alert('Login Failed', result.error);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.hero}>
        <Ionicons name="leaf" size={60} color={COLORS.background} />
        <Text style={styles.heroTitle}>Welcome Back</Text>
        <Text style={styles.heroSubtitle}>Sign in to access your account</Text>
      </View>

      <View style={styles.section}>
        <TextInput
          style={styles.input}
          placeholder="Email"
          keyboardType="email-address"
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
        />

        <TextInput
          style={styles.input}
          placeholder="Password"
          secureTextEntry
          value={password}
          onChangeText={setPassword}
        />

        <TouchableOpacity
          style={[styles.button, loading && { opacity: 0.6 }]}
          onPress={handleLogin}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={COLORS.background} />
          ) : (
            <Text style={styles.buttonText}>Sign In</Text>
          )}
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.buttonSecondary}
          onPress={() => navigation.navigate('Register')}
        >
          <Text style={styles.buttonSecondaryText}>Create Account</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const RegisterScreen = ({ navigation }) => {
  const [form, setForm] = useState({
    name: '', email: '', password: '', phone: '', company: ''
  });
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();

  const handleRegister = async () => {
    if (!form.name || !form.email || !form.password) {
      Alert.alert('Error', 'Please fill in required fields');
      return;
    }

    setLoading(true);
    const result = await register(form);
    setLoading(false);

    if (result.success) {
      navigation.replace('MainTabs');
    } else {
      Alert.alert('Registration Failed', result.error);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.hero}>
        <Ionicons name="person" size={60} color={COLORS.background} />
        <Text style={styles.heroTitle}>Join K&L</Text>
        <Text style={styles.heroSubtitle}>Create your recycling account</Text>
      </View>

      <View style={styles.section}>
        <TextInput
          style={styles.input}
          placeholder="Full Name *"
          value={form.name}
          onChangeText={(text) => setForm({ ...form, name: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Email *"
          keyboardType="email-address"
          value={form.email}
          onChangeText={(text) => setForm({ ...form, email: text })}
          autoCapitalize="none"
        />

        <TextInput
          style={styles.input}
          placeholder="Password *"
          secureTextEntry
          value={form.password}
          onChangeText={(text) => setForm({ ...form, password: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Phone"
          keyboardType="phone-pad"
          value={form.phone}
          onChangeText={(text) => setForm({ ...form, phone: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Company (optional)"
          value={form.company}
          onChangeText={(text) => setForm({ ...form, company: text })}
        />

        <TouchableOpacity
          style={[styles.button, loading && { opacity: 0.6 }]}
          onPress={handleRegister}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={COLORS.background} />
          ) : (
            <Text style={styles.buttonText}>Create Account</Text>
          )}
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.buttonSecondary}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.buttonSecondaryText}>Already have account?</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

// Home Screen
const HomeScreen = ({ navigation }) => {
  const { user } = useAuth();
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadServices();
  }, []);

  const loadServices = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/services/details`);
      setServices(response.data.services || []);
    } catch (error) {
      console.error('Services load error:', error);
      // Fallback to static data
      setServices([
        { id: 'roll-off', name: 'Roll-Off Containers', description: 'Construction and industrial cleanup', icon: 'Truck' },
        { id: 'mobile-crushing', name: 'Mobile Crushing', description: 'On-site concrete recycling', icon: 'Hammer' },
        { id: 'industrial-demolition', name: 'Industrial Demolition', description: 'REMA certified demolition', icon: 'Hammer' },
        { id: 'public-services', name: 'Public Services', description: 'Government partnerships', icon: 'Building2' }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const getIcon = (iconName) => {
    const icons = { Truck, Hammer, Building2 };
    const IconComponent = icons[iconName] || Recycle;
    return <IconComponent size={32} color={COLORS.primary} />;
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.hero}>
        <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 20 }}>
          <Ionicons name="medal" size={40} color={COLORS.background} />
          <Text style={{ color: COLORS.background, fontSize: 24, marginLeft: 10, fontFamily: 'Inter-Bold' }}>REMA Certified</Text>
        </View>
        <Text style={styles.heroTitle}>East Texas Built{'\n'}Nationally Trusted</Text>
        <Text style={styles.heroSubtitle}>Three generations of integrity in recycling</Text>
      </View>

      <View style={styles.section}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 }}>
          <Text style={styles.sectionHeader}>Our Services</Text>
          <TouchableOpacity onPress={() => navigation.navigate('Services')}>
            <Text style={{ color: COLORS.primary, fontWeight: 'bold', fontFamily: 'Inter-Medium' }}>View All</Text>
          </TouchableOpacity>
        </View>

        {loading ? (
          <ActivityIndicator size="large" color={COLORS.primary} />
        ) : (
          services.slice(0, 3).map((service) => (
            <TouchableOpacity
              key={service.id}
              style={styles.card}
              onPress={() => navigation.navigate('ServiceDetail', { service })}
            >
              <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                {getIcon(service.icon)}
                <View style={{ flex: 1, marginLeft: 15 }}>
                  <Text style={styles.cardTitle}>{service.name}</Text>
                  <Text style={styles.cardText}>{service.description}</Text>
                </View>
              </View>
            </TouchableOpacity>
          ))
        )}

        <View style={{ flexDirection: 'row', gap: 10, marginTop: 20 }}>
          <TouchableOpacity
            style={[styles.button, { flex: 1 }]}
            onPress={() => navigation.navigate('QuickQuote')}
          >
            <Text style={styles.buttonText}>Get Quote</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.buttonSecondary, { flex: 1 }]}
            onPress={() => navigation.navigate('QuickSchedule')}
          >
            <Text style={styles.buttonSecondaryText}>Schedule Pickup</Text>
          </TouchableOpacity>
        </View>
      </View>
    </ScrollView>
  );
};

// Services Stack
const ServicesScreen = ({ navigation }) => {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadServices();
  }, []);

  const loadServices = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/services/details`);
      setServices(response.data.services || []);
    } catch (error) {
      console.error('Services load error:', error);
      setServices([]);
    } finally {
      setLoading(false);
    }
  };

  const getIcon = (iconName) => {
    const icons = { Truck, Hammer, Building2 };
    const IconComponent = icons[iconName] || Recycle;
    return <IconComponent size={32} color={COLORS.primary} />;
  };

  if (loading) return <ActivityIndicator size="large" color={COLORS.primary} />;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Our Services</Text>
      </View>

      <View style={styles.section}>
        {services.map((service) => (
          <TouchableOpacity
            key={service.id}
            style={styles.card}
            onPress={() => navigation.navigate('ServiceDetail', { service })}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              {getIcon(service.icon)}
              <View style={{ flex: 1, marginLeft: 15 }}>
                <Text style={styles.cardTitle}>{service.name}</Text>
                <Text style={styles.cardText}>{service.description}</Text>
                <Text style={{ color: COLORS.primary, fontWeight: 'bold', marginTop: 5, fontFamily: 'Inter-Medium' }}>
                  {service.pricing}
                </Text>
              </View>
            </View>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
};

const ServiceDetailScreen = ({ route, navigation }) => {
  const { service } = route.params;

  const getIcon = (iconName) => {
    const icons = { Truck, Hammer, Building2 };
    const IconComponent = icons[iconName] || Recycle;
    return <IconComponent size={48} color={COLORS.primary} />;
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={{ alignItems: 'center', marginVertical: 20 }}>
          {getIcon(service.icon)}
          <Text style={styles.headerText}>{service.name}</Text>
        </View>
      </View>

      <View style={styles.section}>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Overview</Text>
          <Text style={styles.cardText}>{service.details}</Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Key Features</Text>
          {service.features?.map((feature, index) => (
            <View key={index} style={{ flexDirection: 'row', alignItems: 'center', marginVertical: 5 }}>
              <CheckCircle size={16} color={COLORS.success} />
              <Text style={[styles.cardText, { marginLeft: 10 }]}>{feature}</Text>
            </View>
          ))}
        </View>

        <TouchableOpacity
          style={[styles.button, { marginTop: 20 }]}
          onPress={() => navigation.navigate('QuickQuote', { serviceId: service.id })}
        >
          <Text style={styles.buttonText}>Get a Quote</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

// Materials Screen with Impact Calculator
const MaterialsScreen = ({ navigation }) => {
  const [materials, setMaterials] = useState([]);
  const [calculatorModal, setCalculatorModal] = useState(false);
  const [calculatorForm, setCalculatorForm] = useState({
    materialType: 'ferrous',
    quantity: '',
    unit: 'lbs'
  });
  const [calculatorResult, setCalculatorResult] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMaterials();
  }, []);

  const loadMaterials = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/materials/guide`);
      setMaterials(response.data.materials || []);
    } catch (error) {
      console.error('Materials load error:', error);
      setMaterials([]);
    } finally {
      setLoading(false);
    }
  };

  const calculateImpact = async () => {
    if (!calculatorForm.quantity) {
      Alert.alert('Error', 'Please enter a quantity');
      return;
    }

    try {
      const response = await axios.post(`${API_BASE_URL}/api/impact/calculate`, calculatorForm);
      setCalculatorResult(response.data.impact);
    } catch (error) {
      Alert.alert('Error', 'Could not calculate impact');
    }
  };

  const getIcon = (materialType) => {
    const icons = {
      ferrous: <Zap size={32} color={COLORS.primary} />,
      nonferrous: <Recycle size={32} color={COLORS.primary} />,
      precious: <Star size={32} color={COLORS.primary} />
    };
    return icons[materialType] || <Recycle size={32} color={COLORS.primary} />;
  };

  if (loading) return <ActivityIndicator size="large" color={COLORS.primary} />;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Materials We Buy</Text>
      </View>

      <View style={styles.section}>
        <TouchableOpacity
          style={[styles.button, { marginBottom: 20, backgroundColor: COLORS.accent }]}
          onPress={() => setCalculatorModal(true)}
        >
          <Text style={styles.buttonText}>Environmental Impact Calculator</Text>
        </TouchableOpacity>

        {materials.map((material) => (
          <View key={material.id} style={styles.card}>
            <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 10 }}>
              {getIcon(material.id)}
              <View style={{ flex: 1, marginLeft: 15 }}>
                <Text style={styles.cardTitle}>{material.name}</Text>
                <Text style={{ fontSize: 12, color: COLORS.textSecondary, fontFamily: 'Inter-Medium' }}>
                  {material.category}
                </Text>
              </View>
            </View>

            <Text style={styles.cardText}>{material.description}</Text>

            <View style={{ marginTop: 15 }}>
              <Text style={{ fontWeight: 'bold', marginBottom: 5, fontFamily: 'Inter-Bold' }}>Pricing:</Text>
              <Text style={styles.cardText}>{material.pricing}</Text>

              <Text style={{ fontWeight: 'bold', marginTop: 10, marginBottom: 5, fontFamily: 'Inter-Bold' }}>Tips:</Text>
              <Text style={styles.cardText}>{material.tips}</Text>
            </View>
          </View>
        ))}
      </View>

      {/* Impact Calculator Modal */}
      <Modal visible={calculatorModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>Environmental Impact Calculator</Text>

            <TouchableOpacity
              style={{ position: 'absolute', top: 20, right: 20 }}
              onPress={() => setCalculatorModal(false)}
            >
              <Text style={{ fontSize: 24, color: COLORS.textSecondary }}>×</Text>
            </TouchableOpacity>

            <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 15 }}>
              <Calculator size={24} color={COLORS.primary} />
              <Text style={{ marginLeft: 10, fontSize: 16, fontFamily: 'Inter-Medium' }}>
                Calculate your recycling impact
              </Text>
            </View>

            <View style={{ marginBottom: 20 }}>
              <Text style={{ fontWeight: 'bold', marginBottom: 10, fontFamily: 'Inter-Bold' }}>Material Type</Text>
              {materials.map((material) => (
                <TouchableOpacity
                  key={material.id}
                  style={{
                    flexDirection: 'row',
                    alignItems: 'center',
                    padding: 10,
                    marginBottom: 5,
                    borderRadius: 5,
                    backgroundColor: calculatorForm.materialType === material.id ? COLORS.surface : 'transparent'
                  }}
                  onPress={() => setCalculatorForm({ ...calculatorForm, materialType: material.id })}
                >
                  {getIcon(material.id)}
                  <Text style={{ marginLeft: 10, fontFamily: 'Inter-Regular' }}>{material.name}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <TextInput
              style={styles.input}
              placeholder="Quantity"
              keyboardType="numeric"
              value={calculatorForm.quantity}
              onChangeText={(text) => setCalculatorForm({ ...calculatorForm, quantity: text })}
            />

            <View style={{ flexDirection: 'row', marginBottom: 20 }}>
              <TouchableOpacity
                style={{
                  flex: 1,
                  padding: 15,
                  borderRadius: 5,
                  backgroundColor: calculatorForm.unit === 'lbs' ? COLORS.primary : COLORS.surface,
                  marginRight: 10
                }}
                onPress={() => setCalculatorForm({ ...calculatorForm, unit: 'lbs' })}
              >
                <Text style={{
                  textAlign: 'center',
                  color: calculatorForm.unit === 'lbs' ? COLORS.background : COLORS.text,
                  fontFamily: 'Inter-Medium'
                }}>Pounds (lbs)</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={{
                  flex: 1,
                  padding: 15,
                  borderRadius: 5,
                  backgroundColor: calculatorForm.unit === 'kg' ? COLORS.primary : COLORS.surface
                }}
                onPress={() => setCalculatorForm({ ...calculatorForm, unit: 'kg' })}
              >
                <Text style={{
                  textAlign: 'center',
                  color: calculatorForm.unit === 'kg' ? COLORS.background : COLORS.text,
                  fontFamily: 'Inter-Medium'
                }}>Kilograms (kg)</Text>
              </TouchableOpacity>
            </View>

            <TouchableOpacity style={styles.button} onPress={calculateImpact}>
              <Text style={styles.buttonText}>Calculate Impact</Text>
            </TouchableOpacity>

            {calculatorResult && (
              <View style={[styles.card, { marginTop: 20 }]}>
                <Text style={styles.cardTitle}>Your Impact</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginVertical: 10 }}>
                  <TreePine size={24} color={COLORS.success} />
                  <Text style={{ marginLeft: 10, fontSize: 18, fontFamily: 'Inter-Bold' }}>
                    Saved {calculatorResult.treesEquivalent} trees
                  </Text>
                </View>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginVertical: 10 }}>
                  <Zap size={24} color={COLORS.accent} />
                  <Text style={{ marginLeft: 10, fontSize: 16, fontFamily: 'Inter-Regular' }}>
                    Prevented {calculatorResult.co2Prevented} kg of CO2 emissions
                  </Text>
                </View>
                <Text style={[styles.cardText, { marginTop: 10, fontStyle: 'italic' }]}>
                  {calculatorResult.explanation}
                </Text>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
};

// Quick Quote/Schedule Screens
const QuickQuoteScreen = ({ route }) => {
  const { user } = useAuth();
  const { serviceId } = route.params || {};
  const [form, setForm] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: '',
    company: user?.company || '',
    material: '',
    quantity: '',
    notes: '',
    photos: []
  });
  const [images, setImages] = useState([]);
  const [loading, setLoading] = useState(false);

  const pickImages = () => {
    launchImageLibrary({
      mediaType: 'photo',
      includeBase64: false,
      maxHeight: 2000,
      maxWidth: 2000,
      selectionLimit: 5
    }, (response) => {
      if (response.didCancel) return;
      if (response.errorMessage) {
        Alert.alert('Error', response.errorMessage);
        return;
      }

      if (response.assets) {
        const newImages = response.assets.map(asset => ({
          uri: asset.uri,
          fileName: asset.fileName,
          type: asset.type,
          size: asset.fileSize
        }));
        setImages([...images, ...newImages]);
      }
    });
  };

  const removeImage = (index) => {
    const updatedImages = images.filter((_, i) => i !== index);
    setImages(updatedImages);
  };

  const handleSubmit = async () => {
    if (!form.name || !form.email) {
      Alert.alert('Error', 'Please fill in required fields');
      return;
    }

    setLoading(true);
    try {
      // Upload images first if any
      const photoUploads = [];
      for (const image of images) {
        const formData = new FormData();
        formData.append('photo', {
          uri: image.uri,
          type: image.type,
          name: image.fileName,
        });
        formData.append('purpose', 'quote');

        const uploadResponse = await axios.post(`${API_BASE_URL}/api/uploads/photos`, formData, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        photoUploads.push(uploadResponse.data.upload);
      }

      const quoteData = {
        ...form,
        photos: photoUploads
      };

      const response = await axios.post(`${API_BASE_URL}/api/quote`, quoteData);
      Alert.alert('Success', response.data.message);

      // Reset form
      setForm({
        name: user?.name || '',
        email: user?.email || '',
        phone: '',
        company: user?.company || '',
        material: '',
        quantity: '',
        notes: '',
        photos: []
      });
      setImages([]);
    } catch (error) {
      Alert.alert('Error', 'Failed to submit quote. Try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Get a Free Quote</Text>
      </View>

      <View style={styles.section}>
        <TextInput
          style={styles.input}
          placeholder="Full Name *"
          value={form.name}
          onChangeText={(text) => setForm({ ...form, name: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Email *"
          keyboardType="email-address"
          value={form.email}
          onChangeText={(text) => setForm({ ...form, email: text })}
          autoCapitalize="none"
        />

        <TextInput
          style={styles.input}
          placeholder="Phone"
          keyboardType="phone-pad"
          value={form.phone}
          onChangeText={(text) => setForm({ ...form, phone: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Company (optional)"
          value={form.company}
          onChangeText={(text) => setForm({ ...form, company: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Material Type"
          value={form.material}
          onChangeText={(text) => setForm({ ...form, material: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Estimated Quantity"
          keyboardType="numeric"
          value={form.quantity}
          onChangeText={(text) => setForm({ ...form, quantity: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Additional Notes"
          multiline
          numberOfLines={4}
          value={form.notes}
          onChangeText={(text) => setForm({ ...form, notes: text })}
        />

        <TouchableOpacity
          style={[styles.button, { backgroundColor: COLORS.accent }]}
          onPress={pickImages}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Camera size={20} color={COLORS.background} />
            <Text style={[styles.buttonText, { marginLeft: 8 }]}>Add Photos (Optional)</Text>
          </View>
        </TouchableOpacity>

        {images.length > 0 && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Selected Photos ({images.length})</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              {images.map((image, index) => (
                <View key={index} style={{ marginRight: 10, alignItems: 'center' }}>
                  <Image
                    source={{ uri: image.uri }}
                    style={{ width: 80, height: 80, borderRadius: 8, marginBottom: 5 }}
                  />
                  <TouchableOpacity
                    style={[styles.button, { padding: 4, width: 60, backgroundColor: COLORS.error }]}
                    onPress={() => removeImage(index)}
                  >
                    <Text style={styles.buttonText}>Remove</Text>
                  </TouchableOpacity>
                </View>
              ))}
            </ScrollView>
          </View>
        )}

        <TouchableOpacity
          style={[styles.button, loading && { opacity: 0.6 }]}
          onPress={handleSubmit}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={COLORS.background} />
          ) : (
            <Text style={styles.buttonText}>Submit Quote Request</Text>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

// Quick Schedule Screen
const QuickScheduleScreen = ({ route }) => {
  const { user } = useAuth();
  const [form, setForm] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: '',
    company: user?.company || '',
    materialType: '',
    pickupAddress: '',
    pickupDate: '',
    notes: '',
    photos: []
  });
  const [images, setImages] = useState([]);
  const [loading, setLoading] = useState(false);

  const pickImages = () => {
    launchImageLibrary({
      mediaType: 'photo',
      includeBase64: false,
      maxHeight: 2000,
      maxWidth: 2000,
      selectionLimit: 5
    }, (response) => {
      if (response.didCancel) return;
      if (response.errorMessage) {
        Alert.alert('Error', response.errorMessage);
        return;
      }

      if (response.assets) {
        const newImages = response.assets.map(asset => ({
          uri: asset.uri,
          fileName: asset.fileName,
          type: asset.type,
          size: asset.fileSize
        }));
        setImages([...images, ...newImages]);
      }
    });
  };

  const removeImage = (index) => {
    const updatedImages = images.filter((_, i) => i !== index);
    setImages(updatedImages);
  };

  const handleSubmit = async () => {
    if (!form.name || !form.email || !form.pickupAddress || !form.materialType) {
      Alert.alert('Error', 'Please fill in required fields');
      return;
    }

    setLoading(true);
    try {
      // Upload images first if any
      const photoUploads = [];
      for (const image of images) {
        const formData = new FormData();
        formData.append('photo', {
          uri: image.uri,
          type: image.type,
          name: image.fileName,
        });
        formData.append('purpose', 'schedule');

        const uploadResponse = await axios.post(`${API_BASE_URL}/api/uploads/photos`, formData, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        photoUploads.push(uploadResponse.data.upload);
      }

      const scheduleData = {
        ...form,
        photos: photoUploads
      };

      const response = await axios.post(`${API_BASE_URL}/api/schedule`, scheduleData);
      Alert.alert('Success', response.data.message);

      // Reset form
      setForm({
        name: user?.name || '',
        email: user?.email || '',
        phone: '',
        company: user?.company || '',
        materialType: '',
        pickupAddress: '',
        pickupDate: '',
        notes: '',
        photos: []
      });
      setImages([]);
    } catch (error) {
      Alert.alert('Error', 'Failed to schedule pickup. Try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Schedule Pickup</Text>
      </View>

      <View style={styles.section}>
        <TextInput
          style={styles.input}
          placeholder="Full Name *"
          value={form.name}
          onChangeText={(text) => setForm({ ...form, name: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Email *"
          keyboardType="email-address"
          value={form.email}
          onChangeText={(text) => setForm({ ...form, email: text })}
          autoCapitalize="none"
        />

        <TextInput
          style={styles.input}
          placeholder="Phone"
          keyboardType="phone-pad"
          value={form.phone}
          onChangeText={(text) => setForm({ ...form, phone: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Company (optional)"
          value={form.company}
          onChangeText={(text) => setForm({ ...form, company: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Material Type *"
          value={form.materialType}
          onChangeText={(text) => setForm({ ...form, materialType: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Pickup Address *"
          value={form.pickupAddress}
          onChangeText={(text) => setForm({ ...form, pickupAddress: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Preferred Pickup Date"
          value={form.pickupDate}
          onChangeText={(text) => setForm({ ...form, pickupDate: text })}
          placeholderTextColor={COLORS.textSecondary}
        />

        <TextInput
          style={styles.input}
          placeholder="Additional Notes"
          multiline
          numberOfLines={4}
          value={form.notes}
          onChangeText={(text) => setForm({ ...form, notes: text })}
        />

        <TouchableOpacity
          style={[styles.button, { backgroundColor: COLORS.accent }]}
          onPress={pickImages}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Camera size={20} color={COLORS.background} />
            <Text style={[styles.buttonText, { marginLeft: 8 }]}>Add Photos (Optional)</Text>
          </View>
        </TouchableOpacity>

        {images.length > 0 && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Selected Photos ({images.length})</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              {images.map((image, index) => (
                <View key={index} style={{ marginRight: 10, alignItems: 'center' }}>
                  <Image
                    source={{ uri: image.uri }}
                    style={{ width: 80, height: 80, borderRadius: 8, marginBottom: 5 }}
                  />
                  <TouchableOpacity
                    style={[styles.button, { padding: 4, width: 60, backgroundColor: COLORS.error }]}
                    onPress={() => removeImage(index)}
                  >
                    <Text style={styles.buttonText}>Remove</Text>
                  </TouchableOpacity>
                </View>
              ))}
            </ScrollView>
          </View>
        )}

        <TouchableOpacity
          style={[styles.button, loading && { opacity: 0.6 }]}
          onPress={handleSubmit}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={COLORS.background} />
          ) : (
            <Text style={styles.buttonText}>Schedule Pickup</Text>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

// Locations Screen
const LocationsScreen = ({ navigation }) => {
  const [locations, setLocations] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadLocations();
  }, []);

  const loadLocations = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/locations`);
      setLocations(response.data.locations || []);
    } catch (error) {
      console.error('Locations load error:', error);
      setLocations([
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
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <ActivityIndicator size="large" color={COLORS.primary} />;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Our Locations</Text>
        <Text style={{ fontSize: 16, color: COLORS.background, textAlign: 'center', marginTop: 10 }}>
          East Texas & Kansas Coverage
        </Text>
      </View>

      <View style={styles.section}>
        {locations.map((location) => (
          <TouchableOpacity
            key={location.id}
            style={styles.card}
            onPress={() => {
              // Could add navigation to map or detailed location view
            }}
          >
            <Text style={styles.cardTitle}>{location.name}</Text>
            <Text style={styles.cardText}>{location.address}</Text>
            <Text style={{ color: COLORS.primary, fontWeight: 'bold', marginTop: 5, fontFamily: 'Inter-Medium' }}>
              {location.phone}
            </Text>
            <Text style={[styles.cardText, { fontSize: 12, marginTop: 5 }]}>
              Hours: {location.hours}
            </Text>
            <Text style={[styles.cardText, { fontSize: 12, marginTop: 2 }]}>
              Services: {location.services.join(', ')}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
};

// Profile Stack
const ProfileScreen = ({ navigation }) => {
  const { user, logout } = useAuth();
  const [notifications, setNotifications] = useState({
    quotes: true,
    schedules: true,
    promotions: false
  });
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (user) {
      setNotifications(user.notificationSettings || notifications);
    }
  }, [user]);

  const handleLogout = () => {
    Alert.alert(
      'Logout',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Logout', onPress: logout }
      ]
    );
  };

  const updateNotifications = async () => {
    try {
      await axios.put(`${API_BASE_URL}/api/auth/profile`, { notificationSettings: notifications });
      Alert.alert('Success', 'Notification settings updated');
    } catch (error) {
      Alert.alert('Error', 'Failed to update settings');
    }
  };

  if (!user) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={{ marginTop: 20, fontFamily: 'Inter-Regular' }}>Loading profile...</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={() => {}} />
      }
    >
      <View style={styles.header}>
        <View style={{ alignItems: 'center' }}>
          <View style={{
            width: 80,
            height: 80,
            borderRadius: 40,
            backgroundColor: COLORS.surface,
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 10
          }}>
            <User size={40} color={COLORS.primary} />
          </View>
          <Text style={styles.headerText}>{user.name}</Text>
          <Text style={{ color: COLORS.background, opacity: 0.8, fontFamily: 'Inter-Regular' }}>{user.email}</Text>
          {user.company && (
            <Text style={{ color: COLORS.background, opacity: 0.6, fontSize: 14, marginTop: 4, fontFamily: 'Inter-Regular' }}>
              {user.company}
            </Text>
          )}
        </View>
      </View>

      <View style={styles.section}>
        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('ProfileEdit')}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Edit2 size={24} color={COLORS.primary} />
            <View style={{ flex: 1, marginLeft: 15 }}>
              <Text style={styles.cardTitle}>Edit Profile</Text>
              <Text style={styles.cardText}>Update your contact information</Text>
            </View>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('Notifications')}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Bell size={24} color={COLORS.primary} />
            <View style={{ flex: 1, marginLeft: 15 }}>
              <Text style={styles.cardTitle}>Notification Settings</Text>
              <Text style={styles.cardText}>Manage push notification preferences</Text>
            </View>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('History')}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Clock size={24} color={COLORS.primary} />
            <View style={{ flex: 1, marginLeft: 15 }}>
              <Text style={styles.cardTitle}>Activity History</Text>
              <Text style={styles.cardText}>View your recent quotes and schedules</Text>
            </View>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, { marginTop: 30, backgroundColor: COLORS.error }]}
          onPress={handleLogout}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'center' }}>
            <LogOut size={20} color={COLORS.background} />
            <Text style={[styles.buttonText, { marginLeft: 8 }]}>Sign Out</Text>
          </View>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const ProfileEditScreen = () => {
  const { user } = useAuth();
  const [form, setForm] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: user?.phone || '',
    company: user?.company || ''
  });
  const [loading, setLoading] = useState(false);

  const handleSave = async () => {
    if (!form.name || !form.email) {
      Alert.alert('Error', 'Name and email are required');
      return;
    }

    setLoading(true);
    try {
      await axios.put(`${API_BASE_URL}/api/auth/profile`, form);
      Alert.alert('Success', 'Profile updated successfully');
    } catch (error) {
      Alert.alert('Error', 'Failed to update profile');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Edit Profile</Text>
      </View>

      <View style={styles.section}>
        <TextInput
          style={styles.input}
          placeholder="Full Name *"
          value={form.name}
          onChangeText={(text) => setForm({ ...form, name: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Email *"
          keyboardType="email-address"
          value={form.email}
          onChangeText={(text) => setForm({ ...form, email: text })}
          autoCapitalize="none"
        />

        <TextInput
          style={styles.input}
          placeholder="Phone"
          keyboardType="phone-pad"
          value={form.phone}
          onChangeText={(text) => setForm({ ...form, phone: text })}
        />

        <TextInput
          style={styles.input}
          placeholder="Company"
          value={form.company}
          onChangeText={(text) => setForm({ ...form, company: text })}
        />

        <TouchableOpacity
          style={[styles.button, loading && { opacity: 0.6 }]}
          onPress={handleSave}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={COLORS.background} />
          ) : (
            <Text style={styles.buttonText}>Save Changes</Text>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const HistoryScreen = () => {
  const { user } = useAuth();
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadHistory();
  }, []);

  const loadHistory = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/users/history`);
      setActivities(response.data.activities || []);
    } catch (error) {
      console.error('History load error:', error);
      setActivities([]);
    } finally {
      setLoading(false);
    }
  };

  const getActivityIcon = (type) => {
    return type === 'quote' ? <DollarSign size={24} color={COLORS.primary} /> : <Calendar size={24} color={COLORS.primary} />;
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'pending': return COLORS.warning;
      case 'processed': return COLORS.success;
      case 'scheduled': return COLORS.accent;
      case 'confirmed': return COLORS.success;
      default: return COLORS.textSecondary;
    }
  };

  if (loading) return <ActivityIndicator size="large" color={COLORS.primary} />;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Activity History</Text>
      </View>

      <View style={styles.section}>
        {activities.length === 0 ? (
          <View style={styles.card}>
            <Text style={{ textAlign: 'center', color: COLORS.textSecondary, fontFamily: 'Inter-Regular' }}>
              No recent activity found
            </Text>
          </View>
        ) : (
          activities.map((activity) => (
            <View key={activity.id} style={styles.card}>
              <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 10 }}>
                {getActivityIcon(activity.type)}
                <View style={{ flex: 1, marginLeft: 15 }}>
                  <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Text style={styles.cardTitle}>
                      {activity.type === 'quote' ? 'Quote Request' : 'Schedule Request'}
                    </Text>
                    <View style={[
                      styles.badge,
                      { backgroundColor: getStatusColor(activity.status) }
                    ]}>
                      <Text style={styles.badgeText}>{activity.status?.toUpperCase()}</Text>
                    </View>
                  </View>
                </View>
              </View>

              <Text style={styles.cardText}>
                {activity.material || activity.materialType}
                {activity.quantity && ` • ${activity.quantity}`}
              </Text>

              <Text style={[styles.cardText, { fontSize: 12, marginTop: 5 }]}>
                {new Date(activity.createdAt).toLocaleDateString()}
              </Text>

              {activity.notes && (
                <Text style={[styles.cardText, { fontSize: 12, marginTop: 5, fontStyle: 'italic' }]}>
                  "{activity.notes}"
                </Text>
              )}
            </View>
          ))
        )}
      </View>
    </ScrollView>
  );
};

// Navigation Setup
const ServicesStack = () => (
  <Stack.Navigator screenOptions={{ headerShown: false }}>
    <Stack.Screen name="Services" component={ServicesScreen} />
    <Stack.Screen name="ServiceDetail" component={ServiceDetailScreen} />
  </Stack.Navigator>
);

const ProfileStack = () => (
  <Stack.Navigator screenOptions={{ headerShown: false }}>
    <Stack.Screen name="Profile" component={ProfileScreen} />
    <Stack.Screen name="ProfileEdit" component={ProfileEditScreen} />
    <Stack.Screen name="History" component={HistoryScreen} />
  </Stack.Navigator>
);

const MainTabs = () => {
  const { user } = useAuth();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: COLORS.background,
        tabBarInactiveTintColor: COLORS.background + '80',
        tabBarLabelStyle: styles.tabBarLabel,
        headerShown: false,
        tabBarIcon: ({ focused, color, size }) => {
          let icon;
          if (route.name === 'HomeTab') icon = <Ionicons name="home" size={size} color={color} />;
          else if (route.name === 'ServicesTab') icon = <Ionicons name="construct" size={size} color={color} />;
          else if (route.name === 'MaterialsTab') icon = <Ionicons name="leaf" size={size} color={color} />;
          else if (route.name === 'QuickTab') icon = <Ionicons name="flash" size={size} color={color} />;
          else if (route.name === 'ProfileTab') icon = <Ionicons name="person" size={size} color={color} />;
          return icon;
        },
      })}
    >
      <Tab.Screen
        name="HomeTab"
        component={HomeScreen}
        options={{ tabBarLabel: 'Home' }}
      />
      <Tab.Screen
        name="ServicesTab"
        component={ServicesStack}
        options={{ tabBarLabel: 'Services' }}
      />
      <Tab.Screen
        name="MaterialsTab"
        component={MaterialsScreen}
        options={{ tabBarLabel: 'Materials' }}
      />
      <Tab.Screen
        name="QuickTab"
        component={QuickActionsScreen}
        options={{ tabBarLabel: 'Quick Actions' }}
      />
      <Tab.Screen
        name="ProfileTab"
        component={ProfileStack}
        options={{
          tabBarLabel: user ? 'Profile' : 'Login',
          tabBarBadge: user ? null : '!',
          tabBarBadgeStyle: styles.badge,
        }}
      />
    </Tab.Navigator>
  );
};

const QuickActionsScreen = ({ navigation }) => {
  const { user } = useAuth();

  if (!user) {
    return (
      <View style={[styles.container, { justifyContent: 'center', alignItems: 'center' }]}>
        <User size={60} color={COLORS.primary} />
        <Text style={{ fontSize: 20, marginVertical: 20, textAlign: 'center', fontFamily: 'Inter-Bold' }}>
          Sign in to access{'\n'}quick actions
        </Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => navigation.navigate('ProfileTab')}
        >
          <Text style={styles.buttonText}>Sign In</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Quick Actions</Text>
      </View>

      <View style={styles.section}>
        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('QuickQuote')}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <DollarSign size={32} color={COLORS.primary} />
            <View style={{ flex: 1, marginLeft: 15 }}>
              <Text style={styles.cardTitle}>Get a Quote</Text>
              <Text style={styles.cardText}>Request pricing for your materials</Text>
            </View>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('QuickSchedule')}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Calendar size={32} color={COLORS.primary} />
            <View style={{ flex: 1, marginLeft: 15 }}>
              <Text style={styles.cardTitle}>Schedule Pickup</Text>
              <Text style={styles.cardText}>Book collection for your materials</Text>
            </View>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('MaterialsTab', { openCalculator: true })}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Calculator size={32} color={COLORS.accent} />
            <View style={{ flex: 1, marginLeft: 15 }}>
              <Text style={styles.cardTitle}>Impact Calculator</Text>
              <Text style={styles.cardText}>See your environmental contribution</Text>
            </View>
          </View>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

// Main App Component
const AppContent = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={{ marginTop: 20, fontFamily: 'Inter-Regular' }}>Loading K&L Recycling...</Text>
      </View>
    );
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {user ? (
        <Stack.Screen name="MainTabs" component={MainTabs} />
      ) : (
        <Stack.Group>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Register" component={RegisterScreen} />
        </Stack.Group>
      )}
      <Stack.Screen name="QuickQuote" component={QuickQuoteScreen} />
      <Stack.Screen name="QuickSchedule" component={QuickScheduleScreen} />
    </Stack.Navigator>
  );
};

const NavigationScreens = () => (
  <NavigationContainer>
    <AppContent />
  </NavigationContainer>
);

// Main App Export with Auth Provider
export default function App() {
  return (
    <AuthProvider>
      <NavigationScreens />
    </AuthProvider>
  );
}
