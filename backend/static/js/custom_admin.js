/* custom_admin.js */

document.addEventListener('DOMContentLoaded', function() {
    console.log('ShareCare Custom Admin Loaded.');
    const capitalizeAdminLabel = () => {
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
        while (walker.nextNode()) {
            const node = walker.currentNode;
            if (node.nodeValue && node.nodeValue.trim() === 'admin') {
                node.nodeValue = 'Admin';
            }
        }
    };

    capitalizeAdminLabel();

    const observer = new MutationObserver(() => capitalizeAdminLabel());
    observer.observe(document.body, { childList: true, subtree: true, characterData: true });
});