using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(Camera))]
public class ProjectionShadow : MonoBehaviour
{

    [SerializeField]
    private int _renderTextureSize = 512;

    private Camera _camera;

    [SerializeField]
    private RenderTexture _renderTexture;

    private void OnEnable()
    {
        _camera = GetComponent<Camera>();
        _renderTexture = new RenderTexture(_renderTextureSize, _renderTextureSize, 0, RenderTextureFormat.RGB565, 0);
        _camera.targetTexture = _renderTexture;
        _camera.SetReplacementShader(Shader.Find("ShadowProjector"), null);
        _camera.depth = -10000;
        _camera.clearFlags = CameraClearFlags.Color;
        _camera.backgroundColor = Color.white;
    }

    private void OnDisable()
    {
        if (_renderTexture != null)
        {
            _camera.targetTexture = null;
            DestroyImmediate(_renderTexture);
        }
    }

    private void OnPostRender()
    {
        var viewMatrix = _camera.worldToCameraMatrix;
        var projectionMatrix = GL.GetGPUProjectionMatrix(_camera.projectionMatrix, true);
        Shader.SetGlobalMatrix("_ShadowProjectorMatrixVP", projectionMatrix * viewMatrix);
        Shader.SetGlobalTexture("_ShadowProjectorTexture", _renderTexture);

        var projectorPos = Vector4.zero;
        projectorPos = _camera.orthographic ? transform.forward : transform.position;
        projectorPos.w = _camera.orthographic ? 0 : 1;
        Shader.SetGlobalVector("_ShadowProjectorPos", projectorPos);
    }

}
