import { useEffect, useRef, type ReactNode } from "react";
import { X } from "lucide-react";

export function Logo({ small = false }: { small?: boolean }) {
  return (
    <div
      className={`brand ${small ? "small" : ""}`}
      aria-label="Matlingo Admin"
    >
      <svg viewBox="0 0 40 40" aria-hidden="true">
        <rect width="40" height="40" rx="12" />
        <path d="m10 27 5-14 5 9 5-9 5 14" />
      </svg>
      <span>
        Matlingo<span className="brand-studio">Admin</span>
      </span>
    </div>
  );
}
export function Dialog({
  title,
  children,
  onClose,
  wide = false,
}: {
  title: string;
  children: ReactNode;
  onClose: () => void;
  wide?: boolean;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const dialog = ref.current!;
    dialog.showModal();
    return () => dialog.close();
  }, []);
  return (
    <dialog
      ref={ref}
      className={`dialog ${wide ? "wide" : ""}`}
      onCancel={(e) => {
        e.preventDefault();
        onClose();
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
      aria-label={title}
    >
      <header>
        <h2>{title}</h2>
        <button className="icon-btn" aria-label="Đóng" onClick={onClose}>
          <X size={20} />
        </button>
      </header>
      {children}
    </dialog>
  );
}
export function Field({
  label,
  value,
  onChange,
  area = false,
  max = 10000,
  type = "text",
  min,
  maxNumber,
}: {
  label: string;
  value: string | number;
  onChange: (value: string) => void;
  area?: boolean;
  max?: number;
  type?: string;
  min?: number;
  maxNumber?: number;
}) {
  return (
    <label className="field">
      <span>{label}</span>
      {area ? (
        <textarea
          value={value}
          maxLength={max}
          rows={3}
          onChange={(e) => onChange(e.target.value)}
        />
      ) : (
        <input
          type={type}
          value={value}
          min={min}
          max={maxNumber}
          maxLength={max}
          onChange={(e) => onChange(e.target.value)}
        />
      )}
    </label>
  );
}
