import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/contact_links.dart';
import '../core/theme.dart';
import 'common.dart';

/// بطاقة «تواصل مع المالك» — لا تظهر إلا للحقول التي عبّأها المالك.
class OwnerContactCard extends StatelessWidget {
  final AppState state;

  const OwnerContactCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = state.l;
    final c = AppColors.of(context);
    final contact = state.ownerContact;
    if (!contact.hasAny) return const SizedBox.shrink();

    final name = contact.displayName(l.en);
    final actions = <Widget>[
      if (contact.phone.isNotEmpty)
        ContactAction(
          icon: Icons.call_rounded,
          label: l.contactPhone,
          url: ContactLinks.phone(contact.phone),
          color: c.green,
        ),
      if (contact.whatsapp.isNotEmpty)
        ContactAction(
          icon: Icons.chat_rounded,
          label: l.contactWhatsapp,
          url: ContactLinks.whatsapp(contact.whatsapp),
          color: const Color(0xFF25D366),
        ),
      if (contact.telegram.isNotEmpty)
        ContactAction(
          icon: Icons.send_rounded,
          label: l.contactTelegram,
          url: ContactLinks.telegram(contact.telegram),
          color: const Color(0xFF2AABEE),
        ),
      if (contact.email.isNotEmpty)
        ContactAction(
          icon: Icons.alternate_email_rounded,
          label: l.contactEmail,
          url: ContactLinks.email(contact.email),
          color: c.blue,
        ),
      if (contact.facebook.isNotEmpty)
        ContactAction(
          icon: Icons.facebook_rounded,
          label: l.contactFacebook,
          url: ContactLinks.facebook(contact.facebook),
          color: const Color(0xFF1877F2),
        ),
      if (contact.instagram.isNotEmpty)
        ContactAction(
          icon: Icons.camera_alt_rounded,
          label: l.contactInstagram,
          url: ContactLinks.instagram(contact.instagram),
          color: const Color(0xFFE1306C),
        ),
      if (contact.tiktok.isNotEmpty)
        ContactAction(
          icon: Icons.music_note_rounded,
          label: l.contactTiktok,
          url: ContactLinks.tiktok(contact.tiktok),
          color: const Color(0xFF111111),
        ),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  size: 17,
                  color: c.gold,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty
                          ? l.contactOwner
                          : '${l.contactOwner} · $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      l.contactSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.5,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: actions),
        ],
      ),
    );
  }
}
