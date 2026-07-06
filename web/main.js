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
