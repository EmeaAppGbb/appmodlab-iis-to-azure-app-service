// Cascade HR Portal - Legacy JavaScript (circa 2016)
(function() {
    'use strict';
    document.addEventListener('DOMContentLoaded', function() {
        var alerts = document.querySelectorAll('.alert');
        alerts.forEach(function(alert) {
            setTimeout(function() {
                alert.style.opacity = '0';
                setTimeout(function() { alert.remove(); }, 500);
            }, 5000);
        });
    });
    if (navigator.userAgent.indexOf('MSIE') !== -1 || navigator.appVersion.indexOf('Trident/') > -1) {
        console.warn('Legacy browser detected. Some features may not work correctly.');
    }
})();
