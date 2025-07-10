import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/Screen/Sheetal/customer/customer_module.dart';
import 'package:sheetal/Screen/Sheetal/expense/expense.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user ID getter
  String? get currentUserId => _auth.currentUser?.uid;

  // Base collections
  CollectionReference get usersCollection => _firestore.collection('users');

  // User document reference
  DocumentReference? get currentUserDoc =>
      currentUserId != null ? usersCollection.doc(currentUserId) : null;

  CollectionReference? get sheetalCollection =>
      currentUserId != null ? currentUserDoc!.collection('sheetal') : null;

  CollectionReference? get categoryCollection =>
      sheetalCollection?.doc('data').collection('category');

  CollectionReference? get invoiceCollection =>
      sheetalCollection?.doc('data').collection('invoice');

  CollectionReference? get collectionCollection =>
      sheetalCollection?.doc('data').collection('collection');

  CollectionReference? get customerCollection =>
      sheetalCollection?.doc('data').collection('customer');

  CollectionReference? get expenseCollection =>
      sheetalCollection?.doc('data').collection('expense');

  CollectionReference? get purchaseCollection =>
      sheetalCollection?.doc('data').collection('purchase');

  CollectionReference? get bankCollection =>
      sheetalCollection?.doc('data').collection('bank');

  Future<UserCredential> registerUser(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      final emailCheck = await _auth.fetchSignInMethodsForEmail(email);
      if (emailCheck.isNotEmpty) {
        throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account already exists for that email.');
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data in Firestore
      await usersCollection.doc(userCredential.user!.uid).set({
        'email': email,
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'phoneNumber': userData['phoneNumber'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      log('Error registering user: $e');
      rethrow;
    }
  }

  Future<UserCredential> loginUser(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      log('Error logging in: $e');
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    return await _auth.signOut();
  }

  Stream<List<Category>> getCategories() {
    if (categoryCollection == null) {
      return Stream.value([]);
    }

    return categoryCollection!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new category
  Future<String?> addCategory(Category category) async {
    if (categoryCollection == null) return null;

    try {
      DocumentReference docRef =
          await categoryCollection!.add(category.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding category: $e');
      return null;
    }
  }

  // Update an existing category
  Future<bool> updateCategory(Category category) async {
    if (categoryCollection == null || category.id == null) return false;

    try {
      await categoryCollection!.doc(category.id).update(category.toMap());
      return true;
    } catch (e) {
      log('Error updating category: $e');
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    if (categoryCollection == null) return false;

    try {
      await categoryCollection!.doc(categoryId).delete();
      return true;
    } catch (e) {
      log('Error deleting category: $e');
      return false;
    }
  }

  // Get a single category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    if (categoryCollection == null) return null;

    try {
      DocumentSnapshot doc = await categoryCollection!.doc(categoryId).get();
      if (doc.exists) {
        return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting category: $e');
      return null;
    }
  }

  Stream<List<Invoice>> getInvoices() {
    if (invoiceCollection == null) {
      return Stream.value([]);
    }

    return invoiceCollection!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Invoice.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

// Add a new invoice
  Future<String?> addInvoice(Invoice invoice) async {
    if (invoiceCollection == null) return null;

    try {
      DocumentReference docRef = await invoiceCollection!.add(invoice.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding invoice: $e');
      return null;
    }
  }

// Update an existing invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    if (invoiceCollection == null || invoice.id == null) return false;

    try {
      await invoiceCollection!.doc(invoice.id).update(invoice.toMap());
      return true;
    } catch (e) {
      log('Error updating invoice: $e');
      return false;
    }
  }

// Delete an invoice
  Future<bool> deleteInvoice(String invoiceId) async {
    if (invoiceCollection == null) return false;

    try {
      await invoiceCollection!.doc(invoiceId).delete();
      return true;
    } catch (e) {
      log('Error deleting invoice: $e');
      return false;
    }
  }

// Get a single invoice by ID
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    if (invoiceCollection == null) return null;

    try {
      DocumentSnapshot doc = await invoiceCollection!.doc(invoiceId).get();
      if (doc.exists) {
        return Invoice.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting invoice: $e');
      return null;
    }
  }

  // Get all collections
  Stream<List<Collection>> getCollections() {
    if (collectionCollection == null) {
      return Stream.value([]);
    }

    return collectionCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Collection.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new collection
  Future<String?> addCollection(Collection collection) async {
    if (collectionCollection == null) return null;

    try {
      DocumentReference docRef =
          await collectionCollection!.add(collection.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding collection: $e');
      return null;
    }
  }

  // Update an existing collection
  Future<bool> updateCollection(Collection collection) async {
    if (collectionCollection == null || collection.id == null) return false;

    try {
      await collectionCollection!.doc(collection.id).update(collection.toMap());
      return true;
    } catch (e) {
      log('Error updating collection: $e');
      return false;
    }
  }

  // Delete a collection
  Future<bool> deleteCollection(String collectionId) async {
    if (collectionCollection == null) return false;

    try {
      await collectionCollection!.doc(collectionId).delete();
      return true;
    } catch (e) {
      log('Error deleting collection: $e');
      return false;
    }
  }

  // Get a single collection by ID
  Future<Collection?> getCollectionById(String collectionId) async {
    if (collectionCollection == null) return null;

    try {
      DocumentSnapshot doc =
          await collectionCollection!.doc(collectionId).get();
      if (doc.exists) {
        return Collection.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting collection: $e');
      return null;
    }
  }

// Get all customers as a stream
  Stream<List<Customer>> getSheetalCustomers() {
    if (customerCollection == null) {
      return Stream.value([]);
    }

    return customerCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

// Add a new customer
  Future<String?> addSheetalCustomer(Customer customer) async {
    if (customerCollection == null) return null;

    try {
      DocumentReference docRef =
          await customerCollection!.add(customer.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding customer: $e');
      return null;
    }
  }

// Update an existing customer
  Future<bool> updateSheetalCustomer(Customer customer) async {
    if (customerCollection == null || customer.id == null) return false;

    try {
      await customerCollection!.doc(customer.id).update(customer.toMap());
      return true;
    } catch (e) {
      log('Error updating customer: $e');
      return false;
    }
  }

// Delete a customer
  Future<bool> deleteSheetalCustomer(String customerId) async {
    if (customerCollection == null) return false;

    try {
      await customerCollection!.doc(customerId).delete();
      return true;
    } catch (e) {
      log('Error deleting customer: $e');
      return false;
    }
  }

// Get a single customer by ID
  Future<Customer?> getSheetalCustomerById(String customerId) async {
    if (customerCollection == null) return null;

    try {
      DocumentSnapshot doc = await customerCollection!.doc(customerId).get();
      if (doc.exists) {
        return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting customer: $e');
      return null;
    }
  }

  // Get all expenses
  Stream<List<Expense>> getSheetaLExpenses() {
    if (expenseCollection == null) {
      return Stream.value([]);
    }

    return expenseCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new expense
  Future<String?> addSheetaLExpense(Expense expense) async {
    if (expenseCollection == null) return null;

    try {
      DocumentReference docRef = await expenseCollection!.add(expense.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding expense: $e');
      return null;
    }
  }

  // Update an existing expense
  Future<bool> updateSheetaLExpense(Expense expense) async {
    if (expenseCollection == null || expense.id == null) return false;

    try {
      await expenseCollection!.doc(expense.id).update(expense.toMap());
      return true;
    } catch (e) {
      log('Error updating expense: $e');
      return false;
    }
  }

  // Delete an expense
  Future<bool> deleteSheetaLExpense(String expenseId) async {
    if (expenseCollection == null) return false;

    try {
      await expenseCollection!.doc(expenseId).delete();
      return true;
    } catch (e) {
      log('Error deleting expense: $e');
      return false;
    }
  }

  // Get a single expense by ID
  Future<Expense?> getExpenseById(String expenseId) async {
    if (expenseCollection == null) return null;

    try {
      DocumentSnapshot doc = await expenseCollection!.doc(expenseId).get();
      if (doc.exists) {
        return Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting expense: $e');
      return null;
    }
  }

  // Get total expenses
  Stream<double> getTotalExpenses() {
    if (expenseCollection == null) {
      return Stream.value(0.0);
    }

    return expenseCollection!.snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
      }
      return total;
    });
  }

  Future<bool> deleteCustomerWithRelatedData(
      String customerId, String customerName) async {
    if (customerCollection == null ||
        invoiceCollection == null ||
        collectionCollection == null) {
      return false;
    }

    try {
      // Start a batch operation for atomic deletion
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Delete the customer
      batch.delete(customerCollection!.doc(customerId));

      // Get and delete all invoices for this customer
      QuerySnapshot invoiceSnapshot = await invoiceCollection!
          .where('customerName', isEqualTo: customerName)
          .get();

      for (QueryDocumentSnapshot doc in invoiceSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Get and delete all collections for this customer
      QuerySnapshot collectionSnapshot = await collectionCollection!
          .where('customerName', isEqualTo: customerName)
          .get();

      for (QueryDocumentSnapshot doc in collectionSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
      return true;
    } catch (e) {
      log('Error deleting customer with related data: $e');
      return false;
    }
  }

// Batch delete invoices
  Future<bool> deleteMultipleInvoices(List<String> invoiceIds) async {
    if (invoiceCollection == null) return false;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String invoiceId in invoiceIds) {
        batch.delete(invoiceCollection!.doc(invoiceId));
      }

      await batch.commit();
      return true;
    } catch (e) {
      log('Error deleting multiple invoices: $e');
      return false;
    }
  }

// Batch delete collections
  Future<bool> deleteMultipleCollections(List<String> collectionIds) async {
    if (collectionCollection == null) return false;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collectionId in collectionIds) {
        batch.delete(collectionCollection!.doc(collectionId));
      }

      await batch.commit();
      return true;
    } catch (e) {
      log('Error deleting multiple collections: $e');
      return false;
    }
  }

// Batch delete customers with their related data
  Future<bool> deleteMultipleCustomersWithRelatedData(
      List<Customer> customers) async {
    if (customerCollection == null ||
        invoiceCollection == null ||
        collectionCollection == null) {
      return false;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (Customer customer in customers) {
        // Delete the customer
        if (customer.id != null) {
          batch.delete(customerCollection!.doc(customer.id!));
        }

        // Get and delete all invoices for this customer
        QuerySnapshot invoiceSnapshot = await invoiceCollection!
            .where('customerName', isEqualTo: customer.name)
            .get();

        for (QueryDocumentSnapshot doc in invoiceSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Get and delete all collections for this customer
        QuerySnapshot collectionSnapshot = await collectionCollection!
            .where('customerName', isEqualTo: customer.name)
            .get();

        for (QueryDocumentSnapshot doc in collectionSnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // Commit the batch
      await batch.commit();
      return true;
    } catch (e) {
      log('Error deleting multiple customers with related data: $e');
      return false;
    }
  }

  Stream<List<Purchase>> getPurchases() {
    if (purchaseCollection == null) {
      return Stream.value([]);
    }

    return purchaseCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Purchase.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

// Add a new purchase
  Future<String?> addPurchase(Purchase purchase) async {
    if (purchaseCollection == null) return null;

    try {
      DocumentReference docRef =
          await purchaseCollection!.add(purchase.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding purchase: $e');
      return null;
    }
  }

// Update an existing purchase
  Future<bool> updatePurchase(Purchase purchase) async {
    if (purchaseCollection == null || purchase.id == null) return false;

    try {
      await purchaseCollection!.doc(purchase.id).update(purchase.toMap());
      return true;
    } catch (e) {
      log('Error updating purchase: $e');
      return false;
    }
  }

// Delete a purchase
  Future<bool> deletePurchase(String purchaseId) async {
    if (purchaseCollection == null) return false;

    try {
      await purchaseCollection!.doc(purchaseId).delete();
      return true;
    } catch (e) {
      log('Error deleting purchase: $e');
      return false;
    }
  }

// Get a single purchase by ID
  Future<Purchase?> getPurchaseById(String purchaseId) async {
    if (purchaseCollection == null) return null;

    try {
      DocumentSnapshot doc = await purchaseCollection!.doc(purchaseId).get();
      if (doc.exists) {
        return Purchase.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting purchase: $e');
      return null;
    }
  }

  Stream<List<Bank>> getBanks() {
    if (bankCollection == null) {
      return Stream.value([]);
    }

    return bankCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bank.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

// Add a new bank
  Future<String?> addBank(Bank bank) async {
    if (bankCollection == null) return null;

    try {
      DocumentReference docRef = await bankCollection!.add(bank.toMap());
      return docRef.id;
    } catch (e) {
      log('Error adding bank: $e');
      return null;
    }
  }

// Update an existing bank
  Future<bool> updateBank(Bank bank) async {
    if (bankCollection == null || bank.id == null) return false;

    try {
      await bankCollection!.doc(bank.id).update(bank.toMap());
      return true;
    } catch (e) {
      log('Error updating bank: $e');
      return false;
    }
  }

// Delete a bank
  Future<bool> deleteBank(String bankId) async {
    if (bankCollection == null) return false;

    try {
      await bankCollection!.doc(bankId).delete();
      return true;
    } catch (e) {
      log('Error deleting bank: $e');
      return false;
    }
  }

// Get a single bank by ID
  Future<Bank?> getBankById(String bankId) async {
    if (bankCollection == null) return null;

    try {
      DocumentSnapshot doc = await bankCollection!.doc(bankId).get();
      if (doc.exists) {
        return Bank.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting bank: $e');
      return null;
    }
  }

  Stream<double> getTotalBankBalance() {
    if (bankCollection == null) {
      return Stream.value(0.0);
    }

    return bankCollection!.snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
      }
      return total;
    });
  }
}
