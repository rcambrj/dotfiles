# PostgreSQL Database Restoration

## Prerequisites

- `kubectl` access to the cluster
- Permissions to create jobs in the `postgres` namespace
- Backup files exist at `/postgres-dumps/{dbname}.dump`

---

## List Available Backups

```bash
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: list-backups
  namespace: postgres
spec:
  ttlSecondsAfterFinished: 60
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: postgres-backup
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-dumps
      containers:
      - name: list
        image: ghcr.io/cloudnative-pg/postgresql:17
        command: ["ls", "-lh", "/postgres-dumps/"]
        volumeMounts:
        - name: data
          mountPath: /postgres-dumps
EOF

# View results
kubectl logs -n postgres -l job.name=list-backups

# Job auto-deletes after 60 seconds
```

---

## Verify Backup Integrity

Before restoring, verify the backup file is valid:

```bash
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: verify-backup
  namespace: postgres
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: postgres-backup
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-dumps
      containers:
      - name: verify
        image: ghcr.io/cloudnative-pg/postgresql:17
        command: ["pg_restore", "--list", "/postgres-dumps/radarr.dump"]
        volumeMounts:
        - name: data
          mountPath: /postgres-dumps
EOF

# View results
kubectl logs -n postgres -l job.name=verify-backup
```

Expected output shows tables, indexes, and data that will be restored.

---

## Restore: radarr Database

**WARNING:** This overwrites all data in the radarr database.

```bash
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: restore-radarr
  namespace: postgres
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: postgres-backup
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-dumps
      - name: backup-password
        secret:
          secretName: postgres-user-backup
          items:
          - key: password
            path: password
      containers:
      - name: restore
        image: ghcr.io/cloudnative-pg/postgresql:17
        command: ["bash", "-c"]
        args:
        - |
          set -euo pipefail
          PGPASSWORD=$(cat /var/run/secrets/postgres-user-backup/password)
          pg_restore -h postgres-rw.postgres.svc.cluster.local \
            -U backup \
            -d radarr \
            --clean \
            --if-exists \
            --single-transaction \
            /postgres-dumps/radarr.dump
        volumeMounts:
        - name: data
          mountPath: /postgres-dumps
        - name: backup-password
          mountPath: /var/run/secrets/postgres-user-backup
          readOnly: true
EOF

# Monitor progress
kubectl logs -n postgres -l job.name=restore-radarr -f
```

---

## Interactive Shell Access

For manual operations on backup files:

```bash
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-shell
  namespace: postgres
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: postgres-backup
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-dumps
      - name: backup-password
        secret:
          secretName: postgres-user-backup
          items:
          - key: password
            path: password
      containers:
      - name: shell
        image: ghcr.io/cloudnative-pg/postgresql:17
        command: ["sleep", "infinity"]
        volumeMounts:
        - name: data
          mountPath: /postgres-dumps
        - name: backup-password
          mountPath: /var/run/secrets/postgres-user-backup
          readOnly: true
EOF

# Get interactive shell
kubectl exec -n postgres -it job/backup-shell -- bash

# When done
kubectl delete job/backup-shell
```

---

## Verification Steps

After restore completes:

```bash
# Check job completed successfully
kubectl get job -n postgres restore-<dbname>

# Connect to database and verify data
kubectl run -n postgres --rm -it --restart=Never --image=ghcr.io/cloudnative-pg/postgresql:17 \
  -- psql -h postgres-rw.postgres.svc.cluster.local -U backup -d <dbname> \
    -c "\dt"  # List tables

# Check row counts
kubectl run -n postgres --rm -it --restart=Never --image=ghcr.io/cloudnative-pg/postgresql:17 \
  -- psql -h postgres-rw.postgres.svc.cluster.local -U backup -d <dbname> \
    -c "SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del FROM pg_stat_user_tables;"
```

---

## Troubleshooting

### Error: "database does not exist"

The target database was dropped. Recreate it first:

```bash
kubectl run -n postgres --rm -it --restart=Never --image=ghcr.io/cloudnative-pg/postgresql:17 \
  -- psql -h postgres-rw.postgres.svc.cluster.local -U backup -d postgres \
    -c "CREATE DATABASE <dbname>;"
```

### Error: "permission denied"

Verify the backup user has access to the database. Check CloudNative-PG Cluster resource has the backup role configured with `inRoles` including the target database owner.

### Error: "connection refused"

PostgreSQL cluster may be down. Check cluster status:

```bash
kubectl get cluster -n postgres postgres
kubectl get pods -n postgres -l app.kubernetes.io/name=cloudnative-pg
```

### Restore hangs or times out

Check network connectivity and database load. The `--single-transaction` flag means the restore will rollback if interrupted. For large databases, consider removing this flag and accepting partial restores on failure.

### Backup file is corrupted

If `pg_restore --list` fails, the backup file is corrupted. Check restic backups for older versions:

```bash
# On a node with restic access
restic snapshots --host <hostname> | grep postgres-dumps
restic restore <snapshot-id> --target /tmp/restore
```

---

## Manual Ad-hoc Backup

Trigger a backup outside the scheduled time:

```bash
kubectl create job -n postgres pg-backup-manual \
  --from=cronjob/pg-backup
```

Monitor:
```bash
kubectl logs -n postgres -l job.name=pg-backup-manual -f
```

---

## Adding New Databases to Backup

To backup additional databases:

1. Edit `kubernetes/postgres/pg-backup-cronjob.yaml`
2. Add database name to `DATABASES` variable:
   ```bash
   DATABASES="radarr sonarr newdatabase"
   ```
3. Apply the updated CronJob
4. Ensure backup user has access (add to CloudNative-PG Cluster `managed.roles` with `inRoles`)

Next scheduled backup will automatically include the new database.
