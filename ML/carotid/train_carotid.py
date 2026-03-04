"""
Carotid artery segmentation training script.
PyTorch + MONAI: Swin-UNETR 2D (224×224), Dice-CE loss, AdamW, cosine LR.
Preprocessing: MedicalDataCleaner (CLAHE + DWT). Augmentation for low-resource probe variability.
Validation: Dice + IMT MAE (mm) for clinical benchmarks.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

import monai
from monai.data import load_image
from monai.losses import DiceCELoss
from monai.metrics import DiceMetric
from monai.transforms import (
    Compose,
    EnsureChannelFirst,
    EnsureType,
    RandFlip,
    RandRotate,
    RandGaussianNoise,
    ScaleIntensityRangePercentiles,
    Resize,
    Transform,
)
from monai.networks.nets import SwinUNETR

from sklearn.model_selection import train_test_split

from preprocessing import MedicalDataCleaner
from imt_utils import imt_mae_mm
from data_qa import filter_and_flag_pairs

IMT_HIGH_RISK_MM = 0.9  # Clinical threshold for stroke risk triage (matches notebook)
SPACING_MM_PER_PIXEL = 0.04


def find_image_mask_pairs(root: Path, exts: Tuple[str, ...] = (".png", ".jpg", ".jpeg")) -> List[Tuple[str, str]]:
    """Find (image_path, mask_path) pairs. Same logic as notebook. Checks Masks/, masks/, Labels/, or _mask suffix."""
    root = Path(root)
    images = [p for p in root.rglob("*") if p.suffix.lower() in exts and "mask" not in p.name.lower()]
    pairs = []
    for img_path in images:
        for mask_dir in ("Masks", "masks", "Labels", "labels", "Mask", "mask"):
            mask_path = root / mask_dir / img_path.name
            if mask_path.exists():
                pairs.append((str(img_path), str(mask_path)))
                break
        else:
            stem, suf = img_path.stem, img_path.suffix
            mask_path = img_path.parent / f"{stem}_mask{suf}"
            if mask_path.exists():
                pairs.append((str(img_path), str(mask_path)))
    return pairs


# --------------- Data ---------------

class MomotCarotidDataset(torch.utils.data.Dataset):
    """
    Dataset for Momot (2022) style carotid ultrasound.
    Expects a list of dicts: {"image": path, "label": path, "spacing_mm_per_pixel": float}.
    """

    def __init__(
        self,
        items: List[Dict[str, Any]],
        cleaner: Optional[MedicalDataCleaner] = None,
        transform: Optional[Transform] = None,
        image_key: str = "image",
        label_key: str = "label",
    ):
        self.items = items
        self.cleaner = cleaner or MedicalDataCleaner()
        self.transform = transform
        self.image_key = image_key
        self.label_key = label_key

    def __len__(self) -> int:
        return len(self.items)

    def __getitem__(self, idx: int) -> Dict[str, Any]:
        item = self.items[idx]
        img = np.load(item[self.image_key]) if str(item[self.image_key]).endswith(".npy") else np.asarray(load_image(item[self.image_key]))
        lbl = np.load(item[self.label_key]) if str(item[self.label_key]).endswith(".npy") else np.asarray(load_image(item[self.label_key]))
        if img.ndim == 3:
            img = img[0]
        if lbl.ndim == 3:
            lbl = lbl[0]
        img = img.astype(np.float32) / (np.max(img) + 1e-8)
        img = self.cleaner(img, apply_clahe=True, apply_dwt=True)
        data = {"image": img[None], "label": lbl[None], "spacing_mm_per_pixel": item.get("spacing_mm_per_pixel", 0.04)}
        if self.transform:
            data = self.transform(data)
        return data


# --------------- Augmentation (MONAI + Cutout / Shadowing) ---------------

class Cutout(Transform):
    """Random rectangular cutout to simulate shadowing / variable probe placement."""

    def __init__(self, num_holes: int = 1, size: Tuple[int, int] = (32, 32), prob: float = 0.5):
        self.num_holes = num_holes
        self.size = size
        self.prob = prob

    def __call__(self, data: Dict[str, Any]) -> Dict[str, Any]:
        if np.random.random() > self.prob:
            return data
        img = data["image"]
        c, h, w = img.shape
        sh, sw = self.size
        for _ in range(self.num_holes):
            y = np.random.randint(0, max(1, h - sh))
            x = np.random.randint(0, max(1, w - sw))
            img[:, y : y + sh, x : x + sw] = 0
        data["image"] = img
        return data


class RandSpeckle(Transform):
    """Add synthetic speckle noise (ultrasound-like) for robustness in peri-urban conditions."""

    def __init__(self, prob: float = 0.3, sigma: float = 0.05):
        self.prob = prob
        self.sigma = sigma

    def __call__(self, data: Dict[str, Any]) -> Dict[str, Any]:
        if np.random.random() > self.prob:
            return data
        img = data["image"].copy()
        noise = np.random.randn(*img.shape).astype(np.float32) * self.sigma * np.clip(img, 0, None)
        data["image"] = img + noise
        return data


def get_train_transforms(img_size: Tuple[int, int]) -> Transform:
    return Compose([
        EnsureChannelFirst(channel_dim="no_channel"),
        RandRotate(range_x=0.2, prob=0.5, mode="bilinear"),
        RandFlip(prob=0.5, spatial_axis=0),
        RandFlip(prob=0.5, spatial_axis=1),
        monai.transforms.Rand2DElastic(
            prob=0.4,
            spacing=(20, 20),
            magnitude_range=(1, 2),
            mode="bilinear",
        ),
        RandGaussianNoise(prob=0.3, std=0.01),
        RandSpeckle(prob=0.3, sigma=0.05),
        ScaleIntensityRangePercentiles(lower=1, upper=99),
        Cutout(num_holes=1, size=(24, 24), prob=0.4),
        Resize(spatial_size=img_size, mode="bilinear"),
        EnsureType("tensor", dtype=torch.float32),
    ])


def get_val_transforms(img_size: Tuple[int, int]) -> Transform:
    return Compose([
        EnsureChannelFirst(channel_dim="no_channel"),
        ScaleIntensityRangePercentiles(lower=1, upper=99),
        Resize(spatial_size=img_size, mode="bilinear"),
        EnsureType("tensor", dtype=torch.float32),
    ])


# --------------- Model ---------------

def build_swin_unetr_2d(
    img_size: Tuple[int, int] = (224, 224),
    in_channels: int = 1,
    out_channels: int = 2,
    pretrained: Optional[str] = None,
    use_checkpoint: bool = True,
) -> nn.Module:
    """
    Swin-UNETR for 2D inputs (224×224).
    pretrained: path to state_dict or "imagenet" / "usf_mae" (if available via MONAI or external).
    """
    model = SwinUNETR(
        img_size=img_size,
        in_channels=in_channels,
        out_channels=out_channels,
        spatial_dims=2,
        use_checkpoint=use_checkpoint,
        feature_size=48,
        hidden_size=768,
        mlp_dim=3072,
        num_heads=12,
        num_layers=4,
        patch_size=2,
        window_size=7,
        dropout_rate=0.2,
    )
    if pretrained and Path(pretrained).exists():
        state = torch.load(pretrained, map_location="cpu")
        if "state_dict" in state:
            state = state["state_dict"]
        # Optional: filter by prefix if encoder-only weights (e.g. ViT)
        model.load_state_dict(state, strict=False)
    return model


# --------------- IMT Validation Callback ---------------

class IMTMAECallback:
    """Validation callback: compute wall thickness MAE (mm) from predicted and ground-truth binary masks."""

    def __init__(
        self,
        spacing_mm_per_pixel: float = 0.04,
        num_classes: int = 2,
    ):
        self.spacing_mm_per_pixel = spacing_mm_per_pixel
        self.num_classes = num_classes

    def __call__(
        self,
        pred: torch.Tensor,
        gt: torch.Tensor,
        spacing_mm_per_pixel: Optional[float] = None,
    ) -> float:
        # pred/gt: (N, C, H, W); binary mask (0=background, >0=foreground)
        pred_np = pred.detach().cpu().numpy()
        gt_np = gt.detach().cpu().numpy()
        if pred_np.shape[1] > 1:
            pred_np = np.argmax(pred_np, axis=1)
        else:
            pred_np = (pred_np[:, 0] > 0.5).astype(np.int32)
        if gt_np.shape[1] > 1:
            gt_np = np.argmax(gt_np, axis=1)
        else:
            gt_np = (gt_np[:, 0] > 0.5).astype(np.int32)
        sp = spacing_mm_per_pixel if spacing_mm_per_pixel is not None else self.spacing_mm_per_pixel
        return imt_mae_mm(pred_np, gt_np, sp)


# --------------- Training Loop ---------------

def train_one_epoch(
    model: nn.Module,
    loader: DataLoader,
    criterion: nn.Module,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
    scheduler: Optional[Any],
) -> float:
    model.train()
    total_loss = 0.0
    n = 0
    for batch in loader:
        inp = batch["image"].to(device)
        seg = batch["label"].to(device).long().squeeze(1)
        if seg.dim() == 3:
            seg = seg.unsqueeze(1)
        optimizer.zero_grad()
        out = model(inp)
        loss = criterion(out, seg)
        loss.backward()
        optimizer.step()
        if scheduler is not None:
            scheduler.step()
        total_loss += loss.item() * inp.size(0)
        n += inp.size(0)
    return total_loss / max(n, 1)


@torch.no_grad()
def validate(
    model: nn.Module,
    loader: DataLoader,
    criterion: nn.Module,
    dice_metric: DiceMetric,
    imt_callback: IMTMAECallback,
    device: torch.device,
    num_classes: int = 2,
) -> Tuple[float, float, float]:
    model.eval()
    total_loss = 0.0
    n = 0
    all_pred = []
    all_gt = []
    spacings: List[float] = []

    for batch in loader:
        inp = batch["image"].to(device)
        seg = batch["label"].to(device)
        sp = batch.get("spacing_mm_per_pixel")
        if isinstance(sp, torch.Tensor):
            sp = sp.cpu().tolist()
        if isinstance(sp, (list, tuple)):
            spacings.extend(sp)
        else:
            spacings.extend([0.04] * inp.size(0))

        out = model(inp)
        seg_onehot = torch.nn.functional.one_hot(seg.squeeze(1).long(), num_classes=num_classes).permute(0, 3, 1, 2).float()
        loss = criterion(out, seg.squeeze(1).long())
        total_loss += loss.item() * inp.size(0)
        n += inp.size(0)

        pred = torch.softmax(out, dim=1)
        dice_metric(y_pred=pred, y=seg_onehot)
        all_pred.append(pred)
        all_gt.append(seg)

    mean_loss = total_loss / max(n, 1)
    dice = dice_metric.aggregate().item()
    dice_metric.reset()

    pred_cat = torch.cat(all_pred, dim=0)
    gt_cat = torch.cat(all_gt, dim=0)
    imt_mae = imt_callback(pred_cat, gt_cat, spacing_mm_per_pixel=spacings[0] if spacings else 0.04)
    return mean_loss, dice, float(imt_mae) if np.isfinite(imt_mae) else -1.0


def main():
    parser = argparse.ArgumentParser(description="Carotid segmentation training")
    parser.add_argument("--data_config", type=str, default=None, help="JSON with train/val lists of {image, label, spacing_mm_per_pixel}")
    parser.add_argument("--data_root", type=str, default=None, help="Folder to discover image/mask pairs (e.g. /content/data); uses data_qa to filter bad pairs")
    parser.add_argument("--img_size", type=int, nargs=2, default=[224, 224])
    parser.add_argument("--in_channels", type=int, default=1)
    parser.add_argument("--out_channels", type=int, default=2)
    parser.add_argument("--epochs", type=int, default=100)
    parser.add_argument("--batch_size", type=int, default=8)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--weight_decay", type=float, default=0.01)
    parser.add_argument("--pretrained", type=str, default=None, help="Path to pretrained encoder/checkpoint (e.g. USF-MAE or ImageNet)")
    parser.add_argument("--output_dir", type=str, default="models")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    torch.manual_seed(args.seed)
    np.random.seed(args.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    img_size = tuple(args.img_size)

    # Data: from JSON config or from data_root (discover + data_qa, same as notebook)
    spacing_mm = SPACING_MM_PER_PIXEL
    if args.data_config and Path(args.data_config).exists():
        with open(args.data_config) as f:
            config = json.load(f)
        train_items = config.get("train", [])
        val_items = config.get("val", [])
        if train_items and isinstance(train_items[0].get("spacing_mm_per_pixel"), (int, float)):
            spacing_mm = train_items[0]["spacing_mm_per_pixel"]
    elif args.data_root and Path(args.data_root).exists():
        pairs = find_image_mask_pairs(Path(args.data_root))
        if not pairs:
            raise FileNotFoundError(f"No image/mask pairs under {args.data_root}. Check folder structure (e.g. Images/ + Masks/).")
        valid_pairs, flagged = filter_and_flag_pairs(pairs, min_coverage_pct=0.001, max_coverage_pct=0.95)
        if flagged:
            print(f"Flagged {len(flagged)} pairs (removed from training)")
        train_pairs, val_pairs = train_test_split(valid_pairs, test_size=0.15, random_state=args.seed)
        train_items = [{"image": i, "label": m, "spacing_mm_per_pixel": spacing_mm} for i, m in train_pairs]
        val_items = [{"image": i, "label": m, "spacing_mm_per_pixel": spacing_mm} for i, m in val_pairs]
        print(f"Train: {len(train_items)}, Val: {len(val_items)}")
    else:
        train_items = []
        val_items = []
    if not train_items:
        raise SystemExit("No training data. Provide --data_config or --data_root (e.g. --data_root /content/data).")

    cleaner = MedicalDataCleaner(
        clahe_clip_limit=2.0,
        dwt_wavelet="db4",
        dwt_level=2,
    )
    train_ds = MomotCarotidDataset(train_items, cleaner=cleaner, transform=get_train_transforms(img_size))
    val_ds = MomotCarotidDataset(val_items, cleaner=cleaner, transform=get_val_transforms(img_size))
    train_loader = DataLoader(train_ds, batch_size=args.batch_size, shuffle=True, num_workers=0, pin_memory=True)
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False, num_workers=0)

    # Model, loss, optimizer, scheduler
    model = build_swin_unetr_2d(
        img_size=img_size,
        in_channels=args.in_channels,
        out_channels=args.out_channels,
        pretrained=args.pretrained,
    ).to(device)
    criterion = DiceCELoss(softmax=True, to_onehot_y=True, ce_weight=torch.tensor([0.5, 0.5]).to(device))
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
    total_steps = len(train_loader) * args.epochs
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=total_steps, eta_min=1e-6)

    dice_metric = DiceMetric(include_background=False, reduction="mean")
    imt_callback = IMTMAECallback(spacing_mm_per_pixel=spacing_mm, num_classes=args.out_channels)

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    best_dice = 0.0
    log_lines = []

    for epoch in range(args.epochs):
        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, device, scheduler)
        val_loss, val_dice, val_imt_mae = validate(model, val_loader, criterion, dice_metric, imt_callback, device, args.out_channels)
        log = f"Epoch {epoch+1}/{args.epochs}  train_loss={train_loss:.4f}  val_loss={val_loss:.4f}  val_dice={val_dice:.4f}  val_IMT_MAE_mm={val_imt_mae:.4f}"
        print(log)
        log_lines.append(log)
        if val_dice > best_dice:
            best_dice = val_dice
            # Same format as notebook for app (FastAPI/Flutter)
            ckpt = {
                "model": model.state_dict(),
                "img_size": img_size,
                "in_channels": args.in_channels,
                "out_channels": args.out_channels,
                "imt_high_risk_mm": IMT_HIGH_RISK_MM,
                "spacing_mm_per_pixel": spacing_mm,
            }
            torch.save(ckpt, out_dir / "best_model.pt")
            torch.save(ckpt, out_dir / "carotid_swin_unetr_2d.pt")
        torch.save({
            "model": model.state_dict(),
            "img_size": img_size,
            "in_channels": args.in_channels,
            "out_channels": args.out_channels,
            "imt_high_risk_mm": IMT_HIGH_RISK_MM,
            "spacing_mm_per_pixel": spacing_mm,
        }, out_dir / "last_model.pt")

    with open(out_dir / "train_log.txt", "w") as f:
        f.write("\n".join(log_lines))
    print("Training finished. Best Dice:", best_dice)
    print(f"StrokeLink triage: IMT ≥ {IMT_HIGH_RISK_MM} mm = high risk (refer to Gasabo District). Model saved to {out_dir}/carotid_swin_unetr_2d.pt")


if __name__ == "__main__":
    main()
