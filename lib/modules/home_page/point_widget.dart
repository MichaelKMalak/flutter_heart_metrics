import 'package:flutter/material.dart';

class PointWidget extends StatelessWidget {
  final Map<DateTime, double> point;

  const PointWidget(this.point, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = point?.keys?.first;
    final stringifiedDate = '${date?.day}/${date?.month}/${date?.year}';
    final value = point?.values?.first?.truncate().toString();
    return point == null
        ? const SizedBox.shrink()
        : Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.indigo,
                      border: Border.all(
                        color: Colors.indigo,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          stringifiedDate,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.indigo,
                  radius: 30,
                  child: Icon(
                    Icons.assessment,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          );
  }
}
