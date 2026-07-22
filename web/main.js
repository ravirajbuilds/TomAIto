// OrchardEye landing. Progressive enhancement only.

const revealEls = document.querySelectorAll(".reveal");

if ("IntersectionObserver" in window) {
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-in");
          io.unobserve(entry.target);
        }
      }
    },
    { threshold: 0.12, rootMargin: "0px 0px -8% 0px" },
  );

  revealEls.forEach((el) => {
    const siblings = Array.from(el.parentElement?.children || []);
    const index = siblings.indexOf(el);
    el.style.transitionDelay = `${Math.min(Math.max(index, 0), 4) * 70}ms`;
    io.observe(el);
  });
} else {
  revealEls.forEach((el) => el.classList.add("is-in"));
}

const nav = document.getElementById("nav");
const navToggle = document.getElementById("navToggle");

if (nav) {
  const onScroll = () => {
    nav.classList.toggle("is-stuck", window.scrollY > 8);
  };

  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
}

if (nav && navToggle) {
  const menu = nav.querySelector(".nav__links");
  const setOpen = (open) => {
    nav.classList.toggle("is-open", open);
    navToggle.setAttribute("aria-expanded", String(open));
    navToggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  };

  navToggle.addEventListener("click", () => setOpen(!nav.classList.contains("is-open")));
  menu?.addEventListener("click", (event) => {
    if (event.target instanceof HTMLAnchorElement) setOpen(false);
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") setOpen(false);
  });
  document.addEventListener("click", (event) => {
    if (!nav.contains(event.target)) setOpen(false);
  });
}

const form = document.getElementById("pilotForm");

if (form instanceof HTMLFormElement) {
  const status = form.querySelector(".pilot__status");
  const setStatus = (message, ok) => {
    if (!status) return;
    status.textContent = message;
    status.dataset.state = ok ? "ok" : "err";
  };

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());
    const name = String(data.name || "").trim();
    const email = String(data.email || "").trim();

    if (!name || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      setStatus("Add your name and a valid email first.", false);
      return;
    }

    const endpoint = form.dataset.endpoint?.trim();
    if (endpoint) {
      try {
        const response = await fetch(endpoint, {
          method: "POST",
          headers: { Accept: "application/json" },
          body: new FormData(form),
        });
        setStatus(
          response.ok ? "Thanks. We'll be in touch about the pilot." : "Something went wrong. Try the email link.",
          response.ok,
        );
        if (response.ok) form.reset();
      } catch {
        setStatus("Network error. Try again, or email us directly.", false);
      }
      return;
    }

    const body = [
      `Name: ${name}`,
      `Email: ${email}`,
      `Orchard: ${String(data.orchard || "").trim() || "-"}`,
      "",
      String(data.message || "").trim(),
    ].join("\n");
    const to = form.dataset.mailto || "ruchiagrawal9221@gmail.com";
    window.location.href =
      `mailto:${to}?subject=${encodeURIComponent("OrchardEye pilot application")}` +
      `&body=${encodeURIComponent(body)}`;
    setStatus("Opening your email app to send the application.", true);
  });
}
