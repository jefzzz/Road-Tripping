using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[System.Serializable]
public class AxleInfo
{
    public WheelCollider leftWheel;
    public WheelCollider rightWheel;
    public bool motor;
    public bool steering;
}

public class Driving : MonoBehaviour
{
    public Transform centerofmass;
    public Rigidbody rigid;
    public float acceleration = 5f;
    public float steeringAssist = 2f;
    public float maxSteeringAssist = 5f;
    public float speedFactor = 0;
    public float forwardVelocity = 0;
    public float accelerationForce = 1;
    public float turnForce = 0;
    

    private void Start()
    {
        rigid = GetComponent<Rigidbody>();
        rigid.centerOfMass = centerofmass.localPosition;
    }
    public void FixedUpdate()
    {
        forwardVelocity = transform.InverseTransformDirection(rigid.velocity).z;
        float steering =  Input.GetAxisRaw("Horizontal");
        Vector3 pos = rigid.worldCenterOfMass - transform.up * rigid.centerOfMass.y;
        rigid.AddForceAtPosition(transform.forward * accelerationForce / 2, pos, ForceMode.VelocityChange);
        rigid.AddRelativeTorque(transform.up * steering, ForceMode.VelocityChange);
        //drag if wheels are on the ground and if at high speed
        Vector3 vel = transform.InverseTransformVector(rigid.velocity);
        float x = vel.x * (1 - .05f); 
        float y = vel.y;
        float z = vel.z;
        rigid.velocity = transform.TransformVector(new Vector3(x, y, z));
                
        Vector3 rot = transform.InverseTransformVector(rigid.angularVelocity);
        x = rot.x;
        y = rot.y * (1 - .05f);
        z = rot.z;
        rigid.angularVelocity = transform.TransformVector(new Vector3(x, y, z)); 
    }
}