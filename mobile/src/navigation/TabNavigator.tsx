import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import HomeScreen from "../screens/HomeScreen";
import ArticlesScreen from "../screens/ArticlesScreen";
import FavoritesScreen from "../screens/FavoritesScreen";
import ProfileScreen from "../screens/ProfileScreen";


const Tab = createBottomTabNavigator();

export default function TabNavigator() {
  return (
    <Tab.Navigator
        screenOptions={{
            headerShown: false,

            tabBarStyle: {
            position: "absolute",
            bottom: 20,
            left: 20,
            right: 20,
            height: 70,
            borderRadius: 25,
            backgroundColor: "rgba(255,255,255,0.2)",
            borderTopWidth: 0,
            elevation: 0,
            },

            tabBarActiveTintColor: "#000",
            tabBarInactiveTintColor: "rgba(0,0,0,0.4)",

            tabBarLabelStyle: {
            fontSize: 12,
            marginBottom: 5,
            },
        }}
        >
      <Tab.Screen name="Accueil" component={HomeScreen} />
      <Tab.Screen name="Articles" component={ArticlesScreen} />
      <Tab.Screen name="Favoris" component={FavoritesScreen} />
      <Tab.Screen name="Compte" component={ProfileScreen} />
    </Tab.Navigator>
  );
}