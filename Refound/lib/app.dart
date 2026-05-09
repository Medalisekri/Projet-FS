import 'package:flutter/material.dart';
import 'theme/apptheme.dart';
import 'screens/splashscreen.dart';
import 'screens/loginscreen.dart';
import 'screens/signupscreen.dart';
import 'package:refound/screens/userdashboard.dart';
import 'package:refound/screens/postitemscreen.dart';
import 'package:refound/screens/locpickerscreen.dart';
import 'package:refound/screens/mapscreen.dart';
import 'package:refound/screens/browsescreen.dart';
import 'package:refound/screens/chatscreen.dart';
import 'package:refound/screens/itemdetailsscreen.dart';
import 'package:refound/screens/chatlsitscreen.dart';
import 'package:refound/screens/mylistingscreen.dart';
import 'package:refound/screens/userprofilescreen.dart';
class ReFoundApp extends StatelessWidget {
  const ReFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReFound',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
      routes: {
        '/welcome': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),     
        '/signup': (_) => const SignupScreen(),    
        '/userdash':(_) =>const HomeScreen(),
        '/postitem':(_)=>const PostItemScreen(),
        '/map':           (_) => const MapScreen(),
        '/pick-location': (_) => const LocationPickerScreen(),
        '/browse':(_)=>const BrowseScreen(),
        '/item-detail': (_) => const ItemDetailScreen(),
        '/chat':        (_) => const ChatScreen(),
        '/messages': (_) => const ChatsListScreen(),
        '/my-listings':(_) => const MyListingsScreen(),
        '/profile':(_) => const ProfileScreen(),
      },
    );
  }
}