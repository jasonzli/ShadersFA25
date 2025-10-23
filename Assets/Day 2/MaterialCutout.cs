using UnityEngine;

public class MaterialCutout : MonoBehaviour
{

    public Material cutoutMaterial;
    public GameObject cutter;

    void Update()
    {
        if (cutter != null && cutoutMaterial != null)
        {
            Vector3 cutterPosition = cutter.transform.position;
            cutoutMaterial.SetVector("_CutoutLocation", new Vector4(cutterPosition.x, cutterPosition.y, cutterPosition.z, 1.0f));
        }
    }
}
