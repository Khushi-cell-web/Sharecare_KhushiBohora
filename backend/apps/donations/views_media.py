"""Campaign media upload: image and gallery."""
import os
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.users.permissions import IsNGO, IsNGOOrAdmin

from .models import DonationRequest

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
MAX_SIZE_MB = 5
MAX_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024


def _validate_image(file):
    ext = os.path.splitext(file.name)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return False, f'Invalid format. Allowed: {", ".join(ALLOWED_EXTENSIONS)}'
    if file.size > MAX_SIZE_BYTES:
        return False, f'File too large. Max {MAX_SIZE_MB}MB.'
    return True, None


class CampaignUploadMediaView(APIView):
    """POST /api/campaigns/upload-media/ - Upload image for campaign."""
    permission_classes = [IsAuthenticated, IsNGOOrAdmin]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        campaign_id = request.data.get('campaign_id')
        image = request.FILES.get('image')
        is_primary = request.data.get('is_primary', 'true').lower() in ('true', '1', 'yes')

        if not campaign_id:
            return Response({'detail': 'campaign_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if not image:
            return Response({'detail': 'image file is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            campaign = DonationRequest.objects.get(pk=campaign_id, created_by=request.user)
        except DonationRequest.DoesNotExist:
            return Response({'detail': 'Campaign not found or not yours.'}, status=status.HTTP_404_NOT_FOUND)

        ok, err = _validate_image(image)
        if not ok:
            return Response({'detail': err}, status=status.HTTP_400_BAD_REQUEST)

        if is_primary:
            if campaign.image:
                campaign.image.delete(save=False)
            campaign.image = image
            campaign.save(update_fields=['image', 'updated_at'])
            url = campaign.image.url if campaign.image else None
            return Response({'url': url, 'field': 'image'}, status=status.HTTP_201_CREATED)

        from django.core.files.storage import default_storage
        path = default_storage.save(f'campaigns/gallery_{campaign_id}_{image.name}', image)
        rel_url = default_storage.url(path)
        url = request.build_absolute_uri(rel_url) if request else rel_url
        gallery = list(campaign.gallery_images or [])
        gallery.append(url)
        campaign.gallery_images = gallery
        campaign.save(update_fields=['gallery_images', 'updated_at'])
        return Response({'url': url, 'field': 'gallery'}, status=status.HTTP_201_CREATED)
