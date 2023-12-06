// ignore_for_file: use_build_context_synchronously, avoid_print, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:mpesa_flutter_plugin/mpesa_flutter_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:safaricom_daraja_module/firebase_options.dart';
import 'package:safaricom_daraja_module/keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MpesaFlutterPlugin.setConsumerKey(mConsumerKey);
  MpesaFlutterPlugin.setConsumerSecret(mConsumerSecret);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  dynamic transactionResult;

  Future<void> startCheckout(
      {required String userPhone, required double amount}) async {
    try {
      transactionResult = await MpesaFlutterPlugin.initializeMpesaSTKPush(
        businessShortCode: "174379",
        transactionType: TransactionType.CustomerPayBillOnline,
        amount: amount,
        partyA: userPhone,
        partyB: "174379",
        callBackURL: Uri(
            scheme: "https",
            host: "us-central1-test-module-app-3abc7.cloudfunctions.net",
            path: "paymentCallback"),
        accountReference: "shoe",
        phoneNumber: userPhone,
        baseUri: Uri(scheme: "https", host: "sandbox.safaricom.co.ke"),
        transactionDesc: "purchase",
        passKey:
            "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
      );

      print("TRANSACTION RESULT: $transactionResult");

      setState(() {
        transactionResult = transactionResult.toString();
      });

      // Upload transaction result to Firestore
      await storeTransactionDetails(transactionResult);
    } catch (e) {
      print("CAUGHT EXCEPTION: $e");
    }
  }

  Future<void> storeTransactionDetails(dynamic transactionDetails) async {
    CollectionReference transactions =
        FirebaseFirestore.instance.collection('transactions');

    await transactions.add({
      'transactionDetails': transactionDetails,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  List<Map<String, dynamic>> itemsOnSale = [
    {
      "image": "assets/images/shoe.jpg",
      "itemName": "Breathable Oxford Casual Shoes",
      "price": 1.0
    }
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.brown[450],
        primarySwatch: Colors.brown,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mpesa Payment plugin'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 4.0,
                    child: Container(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Colors.brown,
                      ),
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                            width: MediaQuery.of(context).size.width * 0.95,
                            child: Image.asset(
                              itemsOnSale[index]["image"],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: Text(
                                  itemsOnSale[index]["itemName"],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                "Ksh. ${itemsOnSale[index]["price"]}",
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                ),
                                onPressed: () async {
                                  var providedContact =
                                      await _showTextInputDialog(context);

                                  if (providedContact != null) {
                                    if (providedContact.isNotEmpty) {
                                      startCheckout(
                                        userPhone: providedContact,
                                        amount: itemsOnSale[index]["price"],
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Empty Number!'),
                                            content: const Text(
                                                "You did not provide a number to be charged."),
                                            actions: <Widget>[
                                              ElevatedButton(
                                                child: const Text("Cancel"),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  }
                                },
                                child: const Text("Checkout"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: itemsOnSale.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                transactionResult != null
                    ? 'Transaction Result: $transactionResult'
                    : 'Transaction Result: No result yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final _textFieldController = TextEditingController();

  Future<String?> _showTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('M-Pesa Number'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "+254..."),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Proceed'),
              onPressed: () =>
                  Navigator.pop(context, _textFieldController.text),
            ),
          ],
        );
      },
    );
  }
}
