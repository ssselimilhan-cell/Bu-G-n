part of 'recommendation_screen.dart';

extension _RecommendationCardImageMethods on _RecommendationScreenState {
  Widget _buildCardImage(
    _Activity activity,
  ) {
    final imageUrl =
        activity.event?.imageUrl;

    if (imageUrl == null ||
        imageUrl.trim().isEmpty) {
      return Container(
        width:
            double.infinity,
        height:
            155,
        color:
            Colors.grey.shade100,
        child:
            Icon(
          activity.type ==
                  _ActivityType.event
              ? Icons
                  .event_outlined
              : Icons
                  .place_outlined,
          size:
              42,
          color:
              Colors.black38,
        ),
      );
    }

    return Image.network(
      imageUrl,
      width:
          double.infinity,
      height:
          155,
      fit:
          BoxFit.cover,
      errorBuilder:
          (_, __, ___) {
        return Container(
          width:
              double.infinity,
          height:
              155,
          color:
              Colors.grey.shade100,
          child:
              Icon(
            Icons
                .event_outlined,
            size:
                42,
            color:
                Colors.black38,
          ),
        );
      },
      loadingBuilder:
          (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress ==
            null) {
          return child;
        }

        return Container(
          width:
              double.infinity,
          height:
              155,
          color:
              Colors.grey.shade100,
          child:
              const Center(
            child:
                SizedBox(
              width:
                  24,
              height:
                  24,
              child:
                  CircularProgressIndicator(
                strokeWidth:
                    2,
              ),
            ),
          ),
        );
      },
    );
  }


}
