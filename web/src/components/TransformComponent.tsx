import { Suspense, useRef, useState, useEffect } from "react";
import { TransformControls } from "@react-three/drei";
import { useNuiEvent, fetchNui } from "../nui-events";
import { Mesh, MathUtils, EulerOrder } from "three";

// Game rotation order → three.js rotation order
// Mapping derived from axis remap: three.x=game.x, three.y=game.z, three.z=-game.y
const GAME_TO_THREE_ORDER: Record<number, EulerOrder> = {
  0: "YZX", // game ZYX
  1: "ZYX", // game YZX
  2: "YXZ", // game ZXY (default)
  3: "XYZ", // game XZY
  4: "ZXY", // game YXZ
  5: "XZY", // game XYZ
};

export const TransformComponent = () => {
  const mesh = useRef<Mesh>(null!);
  const rotOrderRef = useRef<EulerOrder>("YXZ");
  const [currentEntity, setCurrentEntity] = useState<number>();
  const [editorMode, setEditorMode] = useState<
    "translate" | "rotate" | undefined
  >("translate");

  const handleObjectDataUpdate = () => {
    const entity = {
      handle: currentEntity,
      position: {
        x: mesh.current.position.x,
        y: -mesh.current.position.z,
        z: mesh.current.position.y,
      },
      rotation: {
        x: MathUtils.radToDeg(mesh.current.rotation.x),
        y: MathUtils.radToDeg(-mesh.current.rotation.z),
        z: MathUtils.radToDeg(mesh.current.rotation.y),
      },
    };
    fetchNui("moveEntity", entity);
  };

  useNuiEvent("setGizmoEntity", (entity: any) => {
    setCurrentEntity(entity.handle);
    if (!entity.handle) {
      return;
    }

    const gameOrder = entity.rotationOrder ?? 2;
    rotOrderRef.current = GAME_TO_THREE_ORDER[gameOrder] ?? "YXZ";

    mesh.current.position.set(
      entity.position.x,
      entity.position.z,
      -entity.position.y,
    );
    mesh.current.rotation.order = rotOrderRef.current;
    mesh.current.rotation.set(
      MathUtils.degToRad(entity.rotation.x),
      MathUtils.degToRad(entity.rotation.z),
      MathUtils.degToRad(entity.rotation.y),
    );
  });

  useEffect(() => {
    const keyHandler = (e: KeyboardEvent) => {
      switch (e.code) {
        case "KeyR":
          if (editorMode == "rotate") {
            setEditorMode("translate");
            fetchNui("swapMode", { mode: "Translate" });
          } else {
            setEditorMode("rotate");
            fetchNui("swapMode", { mode: "Rotate" });
          }
          break;
        case "Escape":
          fetchNui("finishEdit");
          break;
        default:
          break;
      }
    };
    window.addEventListener("keyup", keyHandler);
    return () => window.removeEventListener("keyup", keyHandler);
  });

  return (
    <Suspense fallback={<p>Loading Gizmo</p>}>
      {currentEntity != null && (
        <TransformControls
          size={0.5}
          object={mesh}
          mode={editorMode}
          space={"local"}
          onObjectChange={handleObjectDataUpdate}
        />
      )}
      <mesh ref={mesh} />
    </Suspense>
  );
};
