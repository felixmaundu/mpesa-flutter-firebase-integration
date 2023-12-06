import 'package:flutter/material.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
// import 'package:mpesa_flutter_plugin/initializer.dart';
// import 'package:mpesa_flutter_plugin/payment_enums.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safaricom_daraja_module/firebase_options.dart';
import 'package:safaricom_daraja_module/keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MpesaFlutterPlugin.setConsumerKey(kConsumerKey);
  MpesaFlutterPlugin.setConsumerSecret(kConsumerSecret);

  runApp(const MyHomePage());
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M-Pesa Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('M-Pesa Payment'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // Initialize the M-Pesa STK Push
              try {
                // Replace with your transaction details
                dynamic result =
                    await MpesaFlutterPlugin.initializeMpesaSTKPush(
                  businessShortCode: "174379",
                  transactionType: TransactionType.CustomerPayBillOnline,
                  amount: 1,
                  partyA: "254791942295",
                  partyB: "174379",
                  callBackURL: Uri(
                      scheme: "https",
                      host:
                          "us-central1-test-module-app-3abc7.cloudfunctions.net",
                      path: "paymentCallback"),
                  accountReference: "she",
                  phoneNumber: "254791942295",
                  baseUri:
                      Uri(scheme: "https", host: "sandbox.safaricom.co.ke"),
                  passKey:
                      "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
                );

                // If successful, store transaction details in Firebase Firestore
                if (result['ResponseCode'] == '0') {
                  await storeTransactionDetails(result);
                  print('Payment initialized successfully');
                } else {
                  print('Failed to initialize payment');
                }
              } catch (e) {
                print('Error initializing payment: $e');
              }
            },
            child: const Text('Initiate Payment'),
          ),
        ),
      ),
    );
  }

  Future<void> storeTransactionDetails(dynamic transactionDetails) async {
    // Replace 'transactions' with your Firestore collection name
    CollectionReference transactions =
        FirebaseFirestore.instance.collection('transactions');

    // Store transaction details in Firestore
    await transactions.add({
      'transactionDetails': transactionDetails,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
