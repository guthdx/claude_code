// Email signup form handler
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('signup-form');
    const emailInput = document.getElementById('email');
    const messageEl = document.getElementById('form-message');

    form.addEventListener('submit', async function(e) {
        e.preventDefault();

        const email = emailInput.value.trim();

        // Basic email validation
        if (!isValidEmail(email)) {
            showMessage('Please enter a valid email address.', 'error');
            return;
        }

        // Store email (for now, just localStorage - can be replaced with API call)
        try {
            // You can replace this with an API call to Mailchimp, ConvertKit, etc.
            storeEmailLocally(email);

            showMessage('Thank you for subscribing! We\'ll keep you updated.', 'success');
            emailInput.value = '';

            // Optional: Send to analytics
            if (typeof gtag !== 'undefined') {
                gtag('event', 'signup', {
                    'event_category': 'engagement',
                    'event_label': 'email_signup'
                });
            }
        } catch (error) {
            showMessage('Something went wrong. Please try again later.', 'error');
            console.error('Signup error:', error);
        }
    });

    function isValidEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }

    function storeEmailLocally(email) {
        const signups = JSON.parse(localStorage.getItem('signups') || '[]');

        // Check if email already exists
        if (signups.includes(email)) {
            throw new Error('Email already registered');
        }

        signups.push({
            email: email,
            timestamp: new Date().toISOString()
        });

        localStorage.setItem('signups', JSON.stringify(signups));
    }

    function showMessage(message, type) {
        messageEl.textContent = message;
        messageEl.className = `form-message ${type}`;

        // Auto-hide success messages after 5 seconds
        if (type === 'success') {
            setTimeout(() => {
                messageEl.className = 'form-message';
            }, 5000);
        }
    }
});

// Smooth scroll effect for any future anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});
