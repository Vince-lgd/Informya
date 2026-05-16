import { NavigationContainer } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';
import TabNavigator from './src/navigation/TabNavigator';

export default function App() {
  return (
    <>
      <View style={styles.container}>
        <Text style={styles.title}>Bienvenue sur Informya !</Text>
        <Text style={styles.subtitle}>Toute l'actualité, en un seul endroit</Text>
        <StatusBar style="auto" />
      </View>
      <NavigationContainer>
        <TabNavigator />
      </NavigationContainer>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#99B4A0',
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
  },
});
