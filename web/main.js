// OrchardEye landing. Progressive enhancement only.
// Scroll-reveal + sticky-nav shadow. No dependencies.

// Reveal on scroll
const els = document.querySelectorAll('.reveal');
if ('IntersectionObserver' in window) {
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) {
      if (e.isIntersecting) {
        e.target.classList.add('is-in');
        io.unobserve(e.target);
      }
    }
  }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });

  // Stagger siblings inside a card grid for a nicer cascade.
  els.forEach((el) => {
    const i = [...(el.parentElement?.children || [])].indexOf(el);
    el.style.transitionDelay = `${Math.min(i, 4) * 70}ms`;
    io.observe(el);
  });
} else {
  els.forEach((el) => el.classList.add('is-in'));
}

// Sticky-nav border/shadow after scroll
const nav = document.getElementById('nav');
const onScroll = () => nav.classList.toggle('is-stuck', window.scrollY > 8);
onScroll();
window.addEventListener('scroll', onScroll, { passive: true });

// Mobile nav: hamburger toggles the dropdown; closes on link tap, Esc, or
// an outside click.
const navToggle = document.getElementById('navToggle');
if (navToggle) {
  const setOpen = (open) => {
    nav.classList.toggle('is-open', open);
    navToggle.setAttribute('aria-expanded', String(open));
    navToggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  };
  navToggle.addEventListener('click', () => setOpen(!nav.classList.contains('is-open')));
  nav.querySelector('.nav__links').addEventListener('click', (e) => {
    if (e.target.tagName === 'A') setOpen(false);
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') setOpen(false); });
  document.addEventListener('click', (e) => {
    if (nav.classList.contains('is-open') && !nav.contains(e.target)) setOpen(false);
  });
}

// Pilot form: validate, then POST to data-endpoint if set, else compose a
// mailto so it works on a static host with no backend.
const form = document.getElementById('pilotForm');
if (form) {
  const status = form.querySelector('.pilot__status');
  const say = (msg, ok) => { status.textContent = msg; status.dataset.state = ok ? 'ok' : 'err'; };

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());
    if (!data.name?.trim() || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(data.email || '')) {
      say('Add your name and a valid email first.', false);
      return;
    }

    const endpoint = form.dataset.endpoint;
    if (endpoint) {
      try {
        const res = await fetch(endpoint, {
          method: 'POST', headers: { Accept: 'application/json' }, body: new FormData(form),
        });
        say(res.ok ? "Thanks. We'll be in touch about the pilot." : 'Something went wrong. Try the email link.', res.ok);
        if (res.ok) form.reset();
      } catch {
        say('Network error. Try again, or email us directly.', false);
      }
      return;
    }

    // No endpoint configured: open the user's mail client, pre-filled.
    const body =
      `Name: ${data.name}\nEmail: ${data.email}\n` +
      `Orchard: ${data.orchard || '—'}\n\n${data.message || ''}`;
    const to = form.dataset.mailto || 'hello@orchardeye.app';
    window.location.href =
      `mailto:${to}?subject=${encodeURIComponent('OrchardEye pilot application')}` +
      `&body=${encodeURIComponent(body)}`;
    say('Opening your email app to send the application…', true);
  });
}
