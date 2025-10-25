import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/providers/loyalty_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferralProgramScreen extends StatefulWidget {
  const ReferralProgramScreen({super.key});

  @override
  State<ReferralProgramScreen> createState() => _ReferralProgramScreenState();
}

class _ReferralProgramScreenState extends State<ReferralProgramScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _localInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    final provider = context.read<LoyaltyProvider>();
    // Initialize with a demo user ID for testing
    await provider.initializeForUser('demo_user_123');
    if (mounted) {
      setState(() {
        _localInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Program'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LoyaltyProvider>(
        builder: (context, provider, child) {
          // Always show content after service is initialized, show loading only initially
          if (!_localInitialized) {
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading loyalty program...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }

          // Always show content after initialization, even if there are errors
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show error banner if there was an error but still show content
                if (provider.hasError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Some features may not work: ${provider.errorMessage}',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: Colors.orange.shade700),
                          onPressed: () => _initializeProvider(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Main content - always show after initialization
                _buildReferralStats(provider),
                const SizedBox(height: 20),
                _buildShareReferral(),
                const SizedBox(height: 20),
                _buildEnterReferralCode(),
                const SizedBox(height: 20),
                if (provider.completedReferrals > 0) _buildReferralHistory(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReferralStats(LoyaltyProvider provider) {
    final completed = provider.completedReferrals;
    final pending = provider.pendingReferrals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Referral Stats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat('Completed', completed, Colors.green),
                if (pending > 0) ...[
                  const SizedBox(width: 20),
                  _buildStat('Pending', pending, Colors.orange),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Earn 100 points for each successful referral!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: const Color(0xFF757575)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareReferral() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Your Referral Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Share K&L Recycling with friends and earn rewards!',
              style: TextStyle(color: const Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _shareReferral,
              icon: const Icon(Icons.share),
              label: const Text('Share Referral Link'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterReferralCode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Have a Referral Code?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter a friend\'s referral code to get started!',
              style: TextStyle(color: const Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Referral Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReferralCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Apply Referral Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralHistory(LoyaltyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referral History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // This would normally show actual referral records from the provider
            const Text('Your successful referrals will appear here.'),
          ],
        ),
      ),
    );
  }

  void _shareReferral() {
    const String referralMessage =
      'Join me at K&L Recycling! Use my referral code to get started and earn rewards. '
      'Download the app and enter code: WELCOME2024';

    Share.share(referralMessage);
  }

  void _submitReferralCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    // In a real implementation, this would validate and submit the referral code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code applied! Welcome to K&L Recycling!')),
    );

    _codeController.clear();
  }
}
