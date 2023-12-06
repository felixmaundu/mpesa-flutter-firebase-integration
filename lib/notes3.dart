import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mpesa_flutter_plugin/initializer.dart';
import 'package:mpesa_flutter_plugin/payment_enums.dart';
import 'package:safaricom_daraja_module/keys.dart';

void main() {
  MpesaFlutterPlugin.setConsumerKey(kConsumerKey);
  MpesaFlutterPlugin.setConsumerSecret(kConsumerSecret);

  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DocumentReference paymentsRef;
  String mUserMail = "bob@keron.co.ke";
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
  }

  Future<void> initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
      paymentsRef =
          FirebaseFirestore.instance.collection('payments').doc(mUserMail);
    } catch (e) {
      print("Firebase Initialization Error: $e");
      setState(() {
        _error = true;
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? getAccountBalance() {
    if (_initialized) {
      return paymentsRef.collection("balance").doc("account").snapshots();
    } else {
      return null;
    }
  }

  Future<void> updateAccount(String mCheckoutRequestID) async {
    try {
      Map<String, String> initData = {
        'CheckoutRequestID': mCheckoutRequestID,
      };
      paymentsRef.set({"info": "$mUserMail receipts data goes here."});
      await paymentsRef
          .collection("deposit")
          .doc(mCheckoutRequestID)
          .set(initData);
      print("Transaction Initialized.");
    } catch (e) {
      print("Failed to init transaction: $e");
    }
  }

  Future<void> startTransaction(
      {required double amount, required String phone}) async {
    try {
      dynamic transactionInitialization =
          await MpesaFlutterPlugin.initializeMpesaSTKPush(
        businessShortCode: "174379",
        transactionType: TransactionType.CustomerPayBillOnline,
        amount: amount,
        partyA: phone,
        partyB: "174379",
        callBackURL: Uri(
            scheme: "https",
            host:
                "us-central1-test-module-app-3abc7.cloudfunctions.net/paymentCallback",
            path: "paymentCallback"),
        accountReference: "she",
        phoneNumber: phone,
        baseUri:
         Uri(scheme: "https", 
         host: "sandbox.safaricom.co.ke"),
        transactionDesc: "purc",
        passKey:
            "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
      );

      var result = transactionInitialization as Map<String, dynamic>;

      if (result.keys.contains("ResponseCode")) {
        String mResponseCode = result["ResponseCode"];
        log("Resulting Code: $mResponseCode");
        if (mResponseCode == '0') {
          updateAccount(result["CheckoutRequestID"]);
        }
      }
      print("RESULT: $transactionInitialization");
    } catch (e) {
      print("Exception Caught in transaction initialization: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Mpesa Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Your account balance:',
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: getAccountBalance(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      strokeWidth: 1.0,
                    );
                  } else if (snapshot.connectionState ==
                      ConnectionState.active) {
                    if (snapshot.hasData && snapshot.data != null) {
                      Map<String, dynamic> documentFields =
                          snapshot.data!.data() ?? {};
                      return Text(
                        documentFields.containsKey("wallet")
                            ? documentFields["wallet"].toString()
                            : "0",
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    } else {
                      return const Text('0!');
                    }
                  } else {
                    return const Text("!");
                  }
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    if (_error) {
      print('Error initializing: $_error');
      return;
    }
    if (!_initialized) {
      print("Firebase not initialized");
      return;
    }

    try {
      startTransaction(amount: 2.0, phone: "254791942295");
    } catch (e) {
      print("Exception in transaction start: $e");
    }
  },
  tooltip: 'Increment',
  label: const Text("Top Up"),
),

      ),
    );
  }
}
