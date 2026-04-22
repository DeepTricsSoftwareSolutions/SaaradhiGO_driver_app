import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';
import 'package:saaradhi_go_driver/core/widgets/status_badge.dart';

class DocumentManagementScreen extends StatelessWidget {
  const DocumentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock document data - in real app, this would come from provider
    final documents = [
      {
        'name': 'Aadhaar Card',
        'status': 'approved',
        'uploadedDate': '2026-04-15',
        'expiryDate': '2031-04-15',
        'imageUrl': null,
      },
      {
        'name': 'Driving License',
        'status': 'pending',
        'uploadedDate': '2026-04-18',
        'expiryDate': '2029-04-18',
        'imageUrl': null,
      },
      {
        'name': 'Vehicle RC',
        'status': 'approved',
        'uploadedDate': '2026-04-16',
        'expiryDate': '2028-04-16',
        'imageUrl': null,
      },
      {
        'name': 'Insurance',
        'status': 'rejected',
        'uploadedDate': '2026-04-17',
        'expiryDate': '2027-04-17',
        'imageUrl': null,
        'rejectionReason': 'Document not clearly visible',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "DOCUMENT MANAGEMENT",
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Header
            FadeInDown(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: AppTheme.primaryGold, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      "Document Verification Status",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Keep your documents updated to continue driving",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Documents List
            ...documents.map((doc) => FadeInUp(
                  delay: Duration(milliseconds: documents.indexOf(doc) * 100),
                  child: _buildDocumentCard(doc, context),
                )),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, BuildContext context) {
    final status = doc['status'] as String;
    final isRejected = status == 'rejected';
    final expiryInfo = _getExpiryInfo(doc['expiryDate'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDocumentIcon(doc['name'] as String),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusBadge(status: status),
                          const SizedBox(width: 8),
                          Text(
                            expiryInfo['text'] as String,
                            style: TextStyle(
                                color: expiryInfo['color'] as Color,
                                fontSize: 12,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isRejected ? Icons.refresh_rounded : Icons.edit_rounded,
                    color: AppTheme.primaryGold,
                  ),
                  onPressed: () => _handleDocumentAction(doc, context),
                ),
              ],
            ),
            if (isRejected && doc['rejectionReason'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.errorRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Rejection Reason: ${doc['rejectionReason']}",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (expiryInfo['showWarning'] as bool) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (expiryInfo['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: (expiryInfo['color'] as Color)
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: expiryInfo['color'] as Color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expiryInfo['warning'] as String,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.primaryGold;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return Colors.white38;
    }
  }

  IconData _getDocumentIcon(String docName) {
    switch (docName) {
      case 'Aadhaar Card':
        return Icons.person_rounded;
      case 'Driving License':
        return Icons.drive_eta_rounded;
      case 'Vehicle RC':
        return Icons.article_rounded;
      case 'Insurance':
        return Icons.security_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  void _handleDocumentAction(Map<String, dynamic> doc, BuildContext context) {
    final status = doc['status'] as String;
    final isRejected = status == 'rejected';

    if (isRejected) {
      // Re-upload document
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Re-upload functionality would open camera/gallery')),
      );
    } else {
      // Edit/Update document
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update document functionality')),
      );
    }
  }

  Map<String, dynamic> _getExpiryInfo(String? expiryDate) {
    if (expiryDate == null) {
      return {
        'text': 'No expiry date',
        'color': Colors.white38,
        'showWarning': false,
        'warning': '',
      };
    }

    try {
      final expiry = DateTime.parse(expiryDate);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;

      if (difference < 0) {
        // Expired
        return {
          'text': 'EXPIRED',
          'color': AppTheme.errorRed,
          'showWarning': true,
          'warning':
              'This document has expired. Please renew immediately to continue driving.',
        };
      } else if (difference <= 30) {
        // Expires within 30 days
        return {
          'text': 'Expires in $difference days',
          'color': Colors.orange,
          'showWarning': true,
          'warning':
              'This document expires soon. Please renew to avoid service interruption.',
        };
      } else if (difference <= 90) {
        // Expires within 90 days
        return {
          'text': 'Expires in $difference days',
          'color': Colors.yellow,
          'showWarning': true,
          'warning':
              'This document will expire in $difference days. Plan to renew.',
        };
      } else {
        // More than 90 days
        return {
          'text': 'Expires: $expiryDate',
          'color': Colors.white38,
          'showWarning': false,
          'warning': '',
        };
      }
    } catch (e) {
      return {
        'text': 'Invalid date',
        'color': Colors.white38,
        'showWarning': false,
        'warning': '',
      };
    }
  }
}
