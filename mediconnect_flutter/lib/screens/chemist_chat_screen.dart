import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/pharmacy_model.dart';
import '../providers/pharmacy_provider.dart';

class ChemistChatScreen extends StatefulWidget {
  final Pharmacy pharmacy;

  const ChemistChatScreen({super.key, required this.pharmacy});

  @override
  State<ChemistChatScreen> createState() => _ChemistChatScreenState();
}

class _ChemistChatScreenState extends State<ChemistChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  final List<String> _quickSuggestions = [
    'Do you have generic Paracetamol in stock?',
    'How fast can you deliver to my address?',
    'Can I upload my doctor prescription here?',
  ];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage(PharmacyProvider prov, String text) {
    if (text.trim().isEmpty) return;
    prov.sendChemistMessage(widget.pharmacy.id, text.trim());
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyProv = Provider.of<PharmacyProvider>(context);
    final messages = pharmacyProv.getMessagesFor(widget.pharmacy.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Icon(Icons.storefront, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pharmacy.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: AppTheme.success, size: 8),
                      SizedBox(width: 4),
                      Text('Direct Chemist Online', style: TextStyle(fontSize: 11, color: AppTheme.success)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Trust Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.secondaryLight,
            child: Row(
              children: [
                const Icon(Icons.handshake_outlined, size: 16, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct communication with ${widget.pharmacy.name}. No aggregator markups.',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
          ),

          // Messages Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.sender == 'user';
                final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUser ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Questions Chips
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _quickSuggestions.map((text) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: AppTheme.surfaceVariant,
                    side: const BorderSide(color: AppTheme.border),
                    label: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                    onPressed: () => _sendMessage(pharmacyProv, text),
                  ),
                );
              }).toList(),
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message to the chemist...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (val) => _sendMessage(pharmacyProv, val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      minimumSize: Size.zero,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () => _sendMessage(pharmacyProv, _msgController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
