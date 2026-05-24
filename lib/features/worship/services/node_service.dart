import 'package:hive_flutter/hive_flutter.dart';
import '../../profile/services/user_service.dart';
import '../models/knowledge_model.dart'; // Now contains Category and Node

class CategoryService {
  static const String boxName = 'categories_box';
  static late Box<Category> _categoryBox;

  static Future<void> init() async {
    // Ensure TypeAdapter is registered before opening the box
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    _categoryBox = await Hive.openBox<Category>(boxName);
  }

  static List<Category> getCategories() {
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];
    return _categoryBox.values.where((c) => c.userId == currentUserId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Category? getCategoryById(String id) {
    return _categoryBox.get(id);
  }

  static Future<void> saveCategory(Category category) async {
    await _categoryBox.put(category.id, category);
  }

  static Future<void> deleteCategory(String id) async {
    // Before deleting a category, we might want to ensure no nodes are linked to it
    // Or update nodes to remove this category ID.
    // For now, let's just delete the category.
    await _categoryBox.delete(id);
  }

  static Future<void> updateCategoryName(String id, String newName) async {
    final category = _categoryBox.get(id);
    if (category != null) {
      category.name = newName;
      await category.save(); // Save changes to Hive
    }
  }
}

class NodeService {
  static const String boxName = 'nodes_box';
  static late Box<Node> _nodeBox;

  static Future<void> init() async {
    // Ensure TypeAdapter is registered before opening the box
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NodeAdapter());
    }
    _nodeBox = await Hive.openBox<Node>(boxName);
  }

  static List<Node> getNodes() {
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];
    return _nodeBox.values.where((n) => n.userId == currentUserId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Node? getNodeById(String id) {
    return _nodeBox.get(id);
  }

  static Future<void> saveNode(Node node) async {
    await _nodeBox.put(node.id, node);
  }

  static Future<void> deleteNode(String id) async {
    // When a node is deleted, we need to remove its ID from any linked nodes.
    final nodeToDelete = _nodeBox.get(id);
    if (nodeToDelete != null) {
      for (final linkedNodeId in nodeToDelete.linkedNodeIds) {
        final linkedNode = _nodeBox.get(linkedNodeId);
        if (linkedNode != null) {
          linkedNode.linkedNodeIds.remove(id);
          await linkedNode.save();
        }
      }
      await _nodeBox.delete(id);
    }
  }

  static Future<void> linkNodes(String nodeId1, String nodeId2) async {
    final node1 = _nodeBox.get(nodeId1);
    final node2 = _nodeBox.get(nodeId2);

    if (node1 != null && node2 != null) {
      if (!node1.linkedNodeIds.contains(nodeId2)) {
        node1.linkedNodeIds.add(nodeId2);
        await node1.save();
      }
      if (!node2.linkedNodeIds.contains(nodeId1)) {
        node2.linkedNodeIds.add(nodeId1);
        await node2.save();
      }
    }
  }

  static Future<void> unlinkNodes(String nodeId1, String nodeId2) async {
    final node1 = _nodeBox.get(nodeId1);
    final node2 = _nodeBox.get(nodeId2);

    if (node1 != null) {
      node1.linkedNodeIds.remove(nodeId2);
      await node1.save();
    }
    if (node2 != null) {
      node2.linkedNodeIds.remove(nodeId1);
      await node2.save();
    }
  }

  static List<Node> searchNodes(String query) {
    if (query.isEmpty) return getNodes();
    
    final allNodes = getNodes();
    final lowerCaseQuery = query.toLowerCase();
    return allNodes.where((node) =>
      node.contentText.toLowerCase().contains(lowerCaseQuery) ||
      (node.sourceName?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
      node.benefits.any((b) => b.toLowerCase().contains(lowerCaseQuery)) ||
      node.tags.any((t) => t.toLowerCase().contains(lowerCaseQuery))
    ).toList();
  }
}