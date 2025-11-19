import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // A singleton pattern to ensure we only have one instance of this service.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android initialization settings. 'app_icon' is the default icon in mipmap.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings.
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
    
    // Request notification permissions on Android 13+
    _requestAndroidPermission();
  }
  
  void _requestAndroidPermission() {
    _notificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  /// Shows a notification indicating that an update has been downloaded.
  void showUpdateDownloadedNotification() {
    // Define the details for the Android notification channel.
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'app_update_channel', // A unique ID for the channel
      'App Updates',        // The name of the channel visible to the user
      channelDescription: 'Notifications for app updates.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification.
    _notificationsPlugin.show(
      0, // Notification ID
      'Update Ready to Install',
      'The a new version is now available.',
      notificationDetails,
      // The 'payload' can be used to handle taps, but for in-app updates,
      // we'll handle the restart from the app itself.
    );
  }
}