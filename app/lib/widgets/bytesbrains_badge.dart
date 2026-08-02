import 'package:flutter/material.dart';

import '../theme/ieye_theme.dart';

/// Where a specialist request goes until the in-app booking flow lands (next PR).
/// iEye Secure's deeper checks and fixes are a BytesBrains service.
const String kBytesBrainsContactEmail = 'contact@bytesbrains.com';

/// A quiet "by BytesBrains" maker's mark — iEye is the product, BytesBrains is the
/// company behind it. Deliberately small and recessive (muted ink, small mark) so
/// it establishes the maker without competing with iEye's own brand.
class BytesBrainsBadge extends StatelessWidget {
  const BytesBrainsBadge({super.key, this.centered = true});

  /// Center the mark (footers) vs. left-align it (inline under content).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'by ',
          style: text.bodyMedium?.copyWith(
            fontSize: 13,
            color: IEyeColors.charcoalMuted,
          ),
        ),
        // The bb monogram — small, on the light (paper) variant of the brand mark.
        Image.asset(
          'assets/bytesbrains-logo.png',
          height: 20,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 6),
        Text(
          'BytesBrains',
          style: text.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: IEyeColors.charcoalSoft,
          ),
        ),
      ],
    );
  }
}
