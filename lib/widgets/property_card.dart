import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/house_model.dart';
import 'dart:io';

class PropertyCard extends StatelessWidget {
  final HouseModel house;
  final VoidCallback? onTap;
  const PropertyCard({Key? key, required this.house, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final img = house.images.isNotEmpty ? house.images.first : null;
    Widget imageWidget;
    if (img != null && img.startsWith('http')) {
      imageWidget = Image.network(
        img,
        width: 200,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildPlaceholder(),
      );
    } else if (img != null) {
      imageWidget = Image.file(
        File(img),
        width: 200,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 3,
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: imageWidget,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: house.status == 'pending' ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        house.status == 'pending' ? 'На проверке' : 'Активно',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.edit, color: Color(0xFF7C5CFC), size: 16),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.link_outlined, color: Color(0xFF7C5CFC), size: 16),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${house.price} ₽',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.title,
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.deepOrangeAccent, size: 14),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(house.location, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.king_bed_outlined, size: 14),
                        const SizedBox(width: 2),
                        Text('${house.bedrooms}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.bathtub, size: 14),
                        const SizedBox(width: 2),
                        Text('${house.bathrooms}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.square_foot, size: 14),
                        const SizedBox(width: 2),
                        Text('${house.area}м²', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 200,
      height: 110,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.home, size: 36, color: Colors.grey)),
    );
  }
} 