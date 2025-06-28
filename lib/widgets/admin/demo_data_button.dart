import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../providers/product_section_provider.dart';

/// Widget for creating demo data with improved functionality
class DemoDataButton extends ConsumerStatefulWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onSuccess;

  const DemoDataButton({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onSuccess,
  });

  @override
  ConsumerState<DemoDataButton> createState() => _DemoDataButtonState();
}

class _DemoDataButtonState extends ConsumerState<DemoDataButton> {
  bool _isLoading = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.icon ?? Icons.auto_fix_high,
                  color: widget.color ?? Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Auto-Fix Data',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _autoFixData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(widget.icon ?? Icons.auto_fix_high),
                label: Text(_isLoading ? 'Fixing...' : 'Auto-Fix Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color ?? Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _createDemoSections,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Demo Sections'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkStatus,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Check Status'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoFixData() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking and fixing data...';
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final result = await firestoreService.checkAndFixData();
      
      setState(() {
        _status = result;
      });

      // Refresh providers
      ref.refresh(productSectionsStreamProvider);
      ref.refresh(productProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Auto-fix completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSuccess?.call();
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Auto-fix failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDemoSections() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating demo sections...';
    });

    try {
      await ref.read(firestoreServiceProvider).createDemoHomeData();
      
      setState(() {
        _status = '✅ Complete demo data created successfully!\nBanners, Categories, Deals, Products & Sections';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Complete demo data created!\nBanners, Categories, Deals, Products & Sections'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }

      widget.onSuccess?.call();
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create demo sections: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking data status...';
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final result = await firestoreService.ensureDataExists();
      
      final buffer = StringBuffer();
      buffer.writeln('📊 DATA STATUS:');
      buffer.writeln('─' * 30);
      buffer.writeln('Products: ${result['productCount']}');
      buffer.writeln('Approved: ${result['approvedProductCount']}');
      buffer.writeln('Sections: ${result['sectionCount']}');
      buffer.writeln('Valid Sections: ${result['validSectionCount']}');
      
      if (result['errors'].isNotEmpty) {
        buffer.writeln('\n❌ Issues:');
        for (final error in result['errors']) {
          buffer.writeln('• $error');
        }
      }
      
      if (result['fixes'].isNotEmpty) {
        buffer.writeln('\n✅ Recent Fixes:');
        for (final fix in result['fixes']) {
          buffer.writeln('• $fix');
        }
      }

      setState(() {
        _status = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error checking status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Floating action button version for quick access
class DemoDataFAB extends ConsumerStatefulWidget {
  const DemoDataFAB({super.key});

  @override
  ConsumerState<DemoDataFAB> createState() => _DemoDataFABState();
}

class _DemoDataFABState extends ConsumerState<DemoDataFAB> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _createDemoData,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.science),
      label: Text(_isLoading ? 'Creating...' : 'Demo Data'),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    );
  }

  /// Create demo data for testing
  Future<void> _createDemoData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(firestoreServiceProvider).createDemoHomeData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Complete demo data created!\nBanners, Categories, Deals, Products & Sections'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 