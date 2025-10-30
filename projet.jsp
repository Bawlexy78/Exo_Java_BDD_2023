<%@ page import="java.util.*, java.time.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
    // --- échappement HTML sans dépendance externe ---
    private static String esc(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&': sb.append("&amp;"); break;
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }
%>
<%
    // ===== Classe interne représentant une tâche (même esprit que ton camarade) =====
    class Task {
        private String title;
        private String description;
        private String dueDate; // yyyy-MM-dd (ou vide)
        private boolean done;

        public Task(String title, String description, String dueDate) {
            this.title = title;
            this.description = description;
            this.dueDate = dueDate;
            this.done = false;
        }

        public String getTitle() { return title; }
        public String getDescription() { return description; }
        public String getDueDate() { return dueDate; }
        public boolean isDone() { return done; }
        public void setDone(boolean done) { this.done = done; }
    }

    request.setCharacterEncoding("UTF-8");

    // ===== Session : récupération/initialisation de la liste =====
    HttpSession sess = request.getSession();
    List<Task> tasks = (List<Task>) sess.getAttribute("tasks");
    if (tasks == null) {
        tasks = new ArrayList<Task>();
        sess.setAttribute("tasks", tasks);
    }

    // ===== Actions (on garde l'approche par index) + PRG pour éviter le repost =====
    String action = request.getParameter("action");
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        if ("add".equals(action)) {
            String title = request.getParameter("title");
            String desc  = request.getParameter("desc");
            String due   = request.getParameter("dueDate");

            if (title != null) title = title.trim();
            if (desc == null) desc = "";
            else desc = desc.trim();

            if (title != null && !title.isEmpty()) {
                tasks.add(new Task(title, desc, due));
            }
            response.sendRedirect(request.getRequestURI());
            return;
        } else if ("delete".equals(action)) {
            try {
                int index = Integer.parseInt(request.getParameter("index"));
                if (index >= 0 && index < tasks.size()) tasks.remove(index);
            } catch (Exception ignore) {}
            response.sendRedirect(request.getRequestURI());
            return;
        } else if ("toggle".equals(action)) {
            try {
                int index = Integer.parseInt(request.getParameter("index"));
                if (index >= 0 && index < tasks.size()) {
                    Task t = tasks.get(index);
                    t.setDone(!t.isDone());
                }
            } catch (Exception ignore) {}
            response.sendRedirect(request.getRequestURI());
            return;
        }
    }

    // ===== Préparation affichage : on sépare À faire / Terminées =====
    List<Integer> todoIdx = new ArrayList<>();
    List<Integer> doneIdx = new ArrayList<>();
    for (int i = 0; i < tasks.size(); i++) {
        if (tasks.get(i).isDone()) doneIdx.add(i);
        else todoIdx.add(i);
    }

    // petite fonction utilitaire pour savoir si en retard (dueDate < today)
    java.util.function.Function<String, Boolean> isLate = d -> {
        try {
            if (d == null || d.isEmpty()) return false;
            LocalDate date = LocalDate.parse(d);
            return date.isBefore(LocalDate.now());
        } catch (Exception e) {
            return false;
        }
    };
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Mini Gestionnaire de Tâches — Vue cartes</title>
    <style>
        :root {
            --bg:#f7f7f9; --text:#222; --muted:#666; --border:#ddd;
            --accent:#2c3e50; --ok:#2ecc71; --warn:#e67e22; --late:#e74c3c;
        }
        * { box-sizing: border-box; }
        body { margin: 20px; font-family: Arial, Helvetica, sans-serif; color: var(--text); background: var(--bg); }
        h1 { margin: 0 0 8px; color: var(--accent); }
        .muted { color: var(--muted); }
        .wrap { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; align-items: start; }
        .column { background: white; border: 1px solid var(--border); border-radius: 8px; padding: 12px; }
        .col-title { font-weight: bold; margin-bottom: 8px; display:flex; justify-content: space-between; align-items:center; }
        .badge { display:inline-block; padding: 2px 8px; border-radius: 999px; font-size: 12px; border:1px solid var(--border); background:#fff; }
        .badge-ok { border-color: var(--ok); color: var(--ok); }
        .badge-warn { border-color: var(--warn); color: var(--warn); }
        .badge-late { border-color: var(--late); color: var(--late); }
        .form-add { background: white; border: 1px solid var(--border); border-radius: 8px; padding: 12px; margin: 16px 0; }
        .form-add label { display:block; font-weight:bold; margin-top:8px; }
        .form-add input[type="text"], .form-add input[type="date"] {
            width: 100%; padding: 8px; border:1px solid var(--border); border-radius:6px;
        }
        .form-row { display:grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .btn { display:inline-block; padding:8px 12px; border:1px solid var(--accent); border-radius:6px; background:#fff; color:var(--accent); text-decoration:none; cursor:pointer; }
        .btn:hover { background:#f1f4f8; }
        .btn-danger { border-color: var(--late); color: var(--late); }
        .btn-danger:hover { background:#fdeaea; }
        .btn-ghost { border-color: var(--border); color: var(--muted); }
        .grid { display:grid; grid-template-columns: 1fr; gap:10px; }
        .card {
            border:1px solid var(--border); background:#fff; border-radius:8px; padding:10px;
            display:grid; grid-template-columns: 1fr auto; gap:8px; align-items:flex-start;
        }
        .title { font-weight:bold; }
        .desc  { color: var(--muted); font-size: 14px; margin-top:2px; }
        .meta  { font-size: 12px; color: var(--muted); margin-top:6px; }
        .late  { color: var(--late); font-weight: bold; }
        .done  { text-decoration: line-through; color: var(--muted); }
        .actions { display:flex; gap:6px; }
        @media (max-width: 900px) { .wrap { grid-template-columns: 1fr; } .form-row { grid-template-columns: 1fr; } }
    </style>
</head>
<body>

    <h1>Mini Gestionnaire de Tâches</h1>
    <div class="muted">JSP unique • Session côté serveur • Affichage en cartes</div>

    <!-- Formulaire d'ajout -->
    <form class="form-add" method="post" autocomplete="off">
        <input type="hidden" name="action" value="add"/>
        <div class="form-row">
            <div>
                <label for="title">Titre *</label>
                <input id="title" name="title" type="text" required/>
            </div>
            <div>
                <label for="dueDate">Date d'échéance</label>
                <input id="dueDate" name="dueDate" type="date"/>
            </div>
        </div>
        <label for="desc">Description</label>
        <input id="desc" name="desc" type="text" />
        <div style="margin-top:10px">
            <button class="btn" type="submit">Ajouter la tâche</button>
            <span class="muted" style="margin-left:8px">Le rafraîchissement ne duplique pas (PRG actif)</span>
        </div>
    </form>

    <div class="wrap">
        <!-- Colonne À faire -->
        <div class="column">
            <div class="col-title">
                <span>À faire</span>
                <span class="badge"><%= todoIdx.size() %></span>
            </div>

            <div class="grid">
            <%
                if (todoIdx.isEmpty()) {
            %>
                <div class="muted">Aucune tâche à faire.</div>
            <%
                } else {
                    for (int pos = 0; pos < todoIdx.size(); pos++) {
                        int i = todoIdx.get(pos);
                        Task t = tasks.get(i);
                        boolean late = isLate.apply(t.getDueDate());
            %>
                <div class="card">
                    <div>
                        <div class="title"><%= esc(t.getTitle()) %></div>
                        <% if (t.getDescription() != null && !t.getDescription().isEmpty()) { %>
                            <div class="desc"><%= esc(t.getDescription()) %></div>
                        <% } %>
                        <div class="meta">
                            <% if (t.getDueDate() != null && !t.getDueDate().isEmpty()) { %>
                                Échéance :
                                <span class="<%= late ? "late" : "" %>"><%= esc(t.getDueDate()) %></span>
                                <% if (late) { %><span class="badge badge-late" style="margin-left:6px;">En retard</span><% } %>
                            <% } else { %>
                                <span class="badge badge-warn">Sans échéance</span>
                            <% } %>
                        </div>
                    </div>
                    <div class="actions">
                        <!-- Basculer -> terminée -->
                        <form method="post">
                            <input type="hidden" name="action" value="toggle"/>
                            <input type="hidden" name="index" value="<%= i %>"/>
                            <button class="btn" type="submit" title="Marquer terminée">✓</button>
                        </form>
                        <!-- Supprimer -->
                        <form method="post" onsubmit="return confirm('Supprimer cette tâche ?');">
                            <input type="hidden" name="action" value="delete"/>
                            <input type="hidden" name="index" value="<%= i %>"/>
                            <button class="btn btn-danger" type="submit" title="Supprimer">🗑</button>
                        </form>
                    </div>
                </div>
            <%
                    }
                }
            %>
            </div>
        </div>

        <!-- Colonne Terminées -->
        <div class="column">
            <div class="col-title">
                <span>Terminées</span>
                <span class="badge badge-ok"><%= doneIdx.size() %></span>
            </div>

            <div class="grid">
            <%
                if (doneIdx.isEmpty()) {
            %>
                <div class="muted">Aucune tâche terminée.</div>
            <%
                } else {
                    for (int pos = 0; pos < doneIdx.size(); pos++) {
                        int i = doneIdx.get(pos);
                        Task t = tasks.get(i);
            %>
                <div class="card">
                    <div>
                        <div class="title done"><%= esc(t.getTitle()) %></div>
                        <% if (t.getDescription() != null && !t.getDescription().isEmpty()) { %>
                            <div class="desc done"><%= esc(t.getDescription()) %></div>
                        <% } %>
                        <div class="meta"><% if (t.getDueDate()!=null && !t.getDueDate().isEmpty()) { %>Échéance : <%= esc(t.getDueDate()) %><% } %></div>
                    </div>
                    <div class="actions">
                        <!-- Rebasculer -> non terminée -->
                        <form method="post">
                            <input type="hidden" name="action" value="toggle"/>
                            <input type="hidden" name="index" value="<%= i %>"/>
                            <button class="btn btn-ghost" type="submit" title="Marquer non terminée">↺</button>
                        </form>
                        <!-- Supprimer -->
                        <form method="post" onsubmit="return confirm('Supprimer cette tâche ?');">
                            <input type="hidden" name="action" value="delete"/>
                            <input type="hidden" name="index" value="<%= i %>"/>
                            <button class="btn btn-danger" type="submit" title="Supprimer">🗑</button>
                        </form>
                    </div>
                </div>
            <%
                    }
                }
            %>
            </div>
        </div>
    </div>
</body>
</html>
