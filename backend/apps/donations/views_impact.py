"""Impact updates: create and list by campaign."""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.users.permissions import IsNGO, IsNGOOrAdmin

from .models import DonationRequest, ImpactUpdate
from .serializers import ImpactUpdateSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsNGOOrAdmin])
def impact_create(request):
    """POST /api/impact/create/ - Create impact update for a campaign."""
    campaign_id = request.data.get('campaign_id')
    if not campaign_id:
        return Response({'detail': 'campaign_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        campaign = DonationRequest.objects.get(pk=campaign_id, created_by=request.user)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found or not yours.'}, status=status.HTTP_404_NOT_FOUND)

    data = {k: v for k, v in request.data.items() if k != 'campaign_id'}
    serializer = ImpactUpdateSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    serializer.save(campaign=campaign)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def impact_list_campaign(request, campaign_id):
    """GET /api/impact/campaign/<id>/ - List impact updates for a campaign."""
    try:
        DonationRequest.objects.get(pk=campaign_id)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)

    updates = ImpactUpdate.objects.filter(campaign_id=campaign_id).order_by('-created_at')
    serializer = ImpactUpdateSerializer(updates, many=True)
    return Response(serializer.data)
