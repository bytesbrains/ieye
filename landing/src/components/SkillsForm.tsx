import { useId, useState } from "react";
import { isValidEmail, submitSkills } from "../lib/submit";

type Status = "idle" | "submitting" | "done" | "error";

const SKILL_OPTIONS = [
  "Engineering / code",
  "Mobile (Flutter / iOS / Android)",
  "Design / UX",
  "Security review",
  "Writing / docs",
  "Testing / QA",
  "Translation (India-first languages)",
  "Something else",
];

export function SkillsForm() {
  const nameId = useId();
  const emailId = useId();
  const noteId = useId();
  const emailErrId = useId();
  const nameErrId = useId();
  const skillsErrId = useId();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [skills, setSkills] = useState<string[]>([]);
  const [note, setNote] = useState("");
  const [touched, setTouched] = useState(false);
  const [status, setStatus] = useState<Status>("idle");
  const [serverError, setServerError] = useState("");

  const nameError = touched && name.trim().length < 2 ? "Please tell us your name." : "";
  const emailError = touched && !isValidEmail(email) ? "Please enter a valid email address." : "";
  const skillsError = touched && skills.length === 0 ? "Pick at least one way you can help." : "";

  function toggleSkill(skill: string) {
    setSkills((prev) =>
      prev.includes(skill) ? prev.filter((s) => s !== skill) : [...prev, skill]
    );
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setTouched(true);
    if (name.trim().length < 2 || !isValidEmail(email) || skills.length === 0) return;
    setStatus("submitting");
    setServerError("");
    const res = await submitSkills({
      name: name.trim(),
      email: email.trim(),
      skills,
      note: note.trim(),
    });
    if (res.ok) {
      setStatus("done");
    } else {
      setStatus("error");
      setServerError(res.error);
    }
  }

  if (status === "done") {
    return (
      <div
        role="status"
        className="rounded-2xl border-2 border-teal/40 bg-teal/5 p-6 text-center"
      >
        <p className="text-xl font-semibold text-charcoal">Thanks for offering to help.</p>
        <p className="mt-2 text-base text-charcoal-soft">
          The repo is private for now while we finish the first version — we&rsquo;ll review and
          reach out about how you can contribute.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} noValidate className="space-y-5">
      <div>
        <label htmlFor={nameId} className="field-label">
          Your name
        </label>
        <input
          id={nameId}
          type="text"
          name="name"
          autoComplete="name"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => setTouched(true)}
          aria-invalid={nameError ? true : undefined}
          aria-describedby={nameError ? nameErrId : undefined}
          className="field-input"
          placeholder="First name is fine"
        />
        {nameError && (
          <p id={nameErrId} className="field-error" role="alert">
            {nameError}
          </p>
        )}
      </div>

      <div>
        <label htmlFor={emailId} className="field-label">
          Email address
        </label>
        <input
          id={emailId}
          type="email"
          name="email"
          autoComplete="email"
          inputMode="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onBlur={() => setTouched(true)}
          aria-invalid={emailError ? true : undefined}
          aria-describedby={emailError ? emailErrId : undefined}
          className="field-input"
          placeholder="you@example.com"
        />
        {emailError && (
          <p id={emailErrId} className="field-error" role="alert">
            {emailError}
          </p>
        )}
      </div>

      <fieldset aria-describedby={skillsError ? skillsErrId : undefined}>
        <legend className="field-label">How can you help? (pick any)</legend>
        <div className="mt-1 grid gap-2 sm:grid-cols-2">
          {SKILL_OPTIONS.map((skill) => {
            const checked = skills.includes(skill);
            return (
              <label
                key={skill}
                className={`flex cursor-pointer items-center gap-3 rounded-lg border-2 px-4 py-3 text-base transition-colors ${
                  checked
                    ? "border-amber-deep bg-amber/5 text-charcoal"
                    : "border-charcoal/15 text-charcoal-soft hover:border-charcoal/30"
                }`}
              >
                <input
                  type="checkbox"
                  className="h-5 w-5 accent-amber-deep"
                  checked={checked}
                  onChange={() => toggleSkill(skill)}
                />
                {skill}
              </label>
            );
          })}
        </div>
        {skillsError && (
          <p id={skillsErrId} className="field-error" role="alert">
            {skillsError}
          </p>
        )}
      </fieldset>

      <div>
        <label htmlFor={noteId} className="field-label">
          Anything you&rsquo;d like to add <span className="font-normal text-charcoal-faint">(optional)</span>
        </label>
        <textarea
          id={noteId}
          name="note"
          rows={3}
          value={note}
          onChange={(e) => setNote(e.target.value)}
          className="field-input"
          placeholder="A link to your work, how much time you have, or why this matters to you."
        />
      </div>

      {status === "error" && (
        <p className="field-error" role="alert">
          {serverError || "Something went wrong. Please try again."}
        </p>
      )}

      <button type="submit" className="btn btn-primary w-full" disabled={status === "submitting"}>
        {status === "submitting" ? "Sending…" : "Offer to help build iEye"}
      </button>
    </form>
  );
}
